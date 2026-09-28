import Foundation
import AppKit
import SQLite3

public final class SilentAPIDispatcher: @unchecked Sendable {
    public static let shared = SilentAPIDispatcher()
    
    private init() {}
    
    /// 动态解析可用的 Codex CLI 路径（兼容新版 ChatGPT.app 目录结构及历史版本）
    public static func resolveCodexBinaryPath() -> String? {
        let fileManager = FileManager.default
        let home = fileManager.homeDirectoryForCurrentUser
        
        let candidatePaths = [
            // 1. ChatGPT.app 最新版本结构 (codex-cli/bin/codex 包装脚本)
            "/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex",
            // 2. ChatGPT.app 最新版本结构 (CodexCLI.app 原生 Mach-O 二进制)
            "/Applications/ChatGPT.app/Contents/Resources/codex-cli/CodexCLI.app/Contents/MacOS/codex",
            // 3. ChatGPT.app 旧版本路径 (Contents/Resources/codex)
            "/Applications/ChatGPT.app/Contents/Resources/codex",
            // 4. 用户目录下的 Applications
            home.appendingPathComponent("Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex").path,
            home.appendingPathComponent("Applications/ChatGPT.app/Contents/Resources/codex-cli/CodexCLI.app/Contents/MacOS/codex").path,
            home.appendingPathComponent("Applications/ChatGPT.app/Contents/Resources/codex").path,
            // 5. 系统标准路径 / Homebrew 路径
            "/usr/local/bin/codex",
            "/opt/homebrew/bin/codex"
        ]
        
        for path in candidatePaths {
            if fileManager.isExecutableFile(atPath: path) {
                return path
            }
        }
        
        // 6. 从 PATH 环境变量检索
        if let pathEnv = ProcessInfo.processInfo.environment["PATH"] {
            for dir in pathEnv.split(separator: ":") {
                let candidate = URL(fileURLWithPath: String(dir)).appendingPathComponent("codex").path
                if fileManager.isExecutableFile(atPath: candidate) {
                    return candidate
                }
            }
        }
        
        return nil
    }
    
    /// 执行后台真实静默发送至本地 Codex 引擎
    public func dispatch(job: ScheduledJob) async throws -> Bool {
        print("🚀 [SilentAPIDispatcher] 正在调用本地 Codex CLI 发送任务: \(job.title)")
        
        guard let codexBinary = Self.resolveCodexBinaryPath() else {
            let errorMsg = L10n.tr(
                zh: "未找到本地 Codex CLI 执行文件（请确认官方 ChatGPT.app 是否安装完整）",
                en: "Codex CLI binary not found. Please verify ChatGPT.app is installed.",
                ja: "Codex CLI バイナリが見つかりません。ChatGPT.app が正しくインストールされているか確認してください"
            )
            print("❌ [SilentAPIDispatcher] \(errorMsg)")
            throw NSError(domain: "SilentAPIDispatcher", code: 404, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
        
        let modelSlug = job.model.slug
        let effortRaw = job.reasoningEffort.rawValue
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: codexBinary)
        process.standardInput = FileHandle.nullDevice
        
        // 补充 GUI 环境可能缺失的 PATH
        var environment = ProcessInfo.processInfo.environment
        let defaultPath = "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        if let existingPath = environment["PATH"], !existingPath.isEmpty {
            environment["PATH"] = "\(existingPath):\(defaultPath)"
        } else {
            environment["PATH"] = defaultPath
        }
        process.environment = environment
        
        var arguments: [String] = []
        var targetThreadId: String? = nil
        
        switch job.destination.conversationAction {
        case .existing(let threadId, _):
            // 追加到已有会话
            targetThreadId = threadId
            arguments = [
                "queue",
                "--thread", threadId,
                "-m", modelSlug,
                "-c", "reasoning_effort=\"\(effortRaw)\"",
                "--message", job.prompt
            ]
            
        case .newSession:
            // 新建独立会话
            var workingDir = FileManager.default.homeDirectoryForCurrentUser.path
            if case .specific(let projId, _) = job.destination.projectScope {
                let projects = LocalCodexContextReader.shared.fetchCategorizedProjectsAndSessions().projects
                if let matched = projects.first(where: { $0.id == projId }), !matched.description.isEmpty {
                    let firstRoot = matched.description.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? ""
                    if FileManager.default.fileExists(atPath: firstRoot) {
                        workingDir = firstRoot
                    }
                }
            }
            
            arguments = [
                "exec",
                "--skip-git-repo-check",
                "-C", workingDir,
                "-m", modelSlug,
                "-c", "reasoning_effort=\"\(effortRaw)\"",
                job.prompt
            ]
        }
        
        process.arguments = arguments
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        let jobPrompt = job.prompt
        let jobTitle = job.title
        
        do {
            try process.run()
            
            return try await withCheckedThrowingContinuation { continuation in
                DispatchQueue.global().async {
                    process.waitUntilExit()
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8) ?? ""
                    print("📄 [Codex CLI Output]:\n\(output)")
                    
                    if process.terminationStatus == 0 {
                        var resolvedSessionId = targetThreadId
                        
                        // 1. 提取新建会话的 session id 并同步到 Codex GUI 的 session_index.jsonl 和 state_5.sqlite
                        if let regex = try? NSRegularExpression(pattern: #"(?:session\s*id|thread\s*id)[:\s]+([0-9a-f\-]+)"#, options: .caseInsensitive),
                           let match = regex.firstMatch(in: output, range: NSRange(output.startIndex..., in: output)),
                           let idRange = Range(match.range(at: 1), in: output) {
                            let sessionId = String(output[idRange])
                            resolvedSessionId = sessionId
                            self.syncNewSessionToCodexGUI(sessionId: sessionId, title: jobPrompt)
                        }
                        
                        // 2. 关键：通过官方 Deep Link (codex://threads/<ID>) 实时通知并刷新正在运行的 Codex 客户端窗口，免重启
                        if let sId = resolvedSessionId {
                            self.notifyCodexGUIToRefresh(sessionId: sId)
                        }
                        
                        // 3. 刷新本地会话和额度快照
                        DispatchQueue.main.async {
                            SessionRouter.shared.reloadData()
                            QuotaProbeEngine.shared.refreshNow()
                        }
                        
                        NotificationService.shared.sendNotification(
                            title: "🎯 Next5h 任务派发成功",
                            body: "已成功向本地 Codex 派发任务：\(jobTitle)"
                        )
                        continuation.resume(returning: true)
                    } else {
                        let errMsg = "Codex CLI 退出码: \(process.terminationStatus) - \(output.prefix(200))"
                        continuation.resume(throwing: NSError(domain: "CodexDispatchError", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: errMsg]))
                    }
                }
            }
        } catch {
            print("❌ [SilentAPIDispatcher] 进程启动失败: \(error)")
            throw error
        }
    }
    
    /// 将新创建的会话同步注册到 Codex 客户端侧边栏可见列表中
    private func syncNewSessionToCodexGUI(sessionId: String, title: String) {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let codexDir = home.appendingPathComponent(".codex")
        
        // 1. 写入 session_index.jsonl
        let sessionIndexURL = codexDir.appendingPathComponent("session_index.jsonl")
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let dateStr = isoFormatter.string(from: Date())
        
        let titleClean = String(title.prefix(40)).replacingOccurrences(of: "\n", with: " ")
        let entry: [String: Any] = [
            "id": sessionId,
            "thread_name": titleClean.isEmpty ? "自动化任务" : titleClean,
            "updated_at": dateStr
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: entry),
           let jsonStr = String(data: data, encoding: .utf8) {
            if let handle = try? FileHandle(forWritingTo: sessionIndexURL) {
                handle.seekToEndOfFile()
                if let lineData = (jsonStr + "\n").data(using: .utf8) {
                    handle.write(lineData)
                }
                try? handle.close()
            }
        }
        
        // 2. 更新 state_5.sqlite 中的 source 为 vscode 确保 GUI 显示
        let dbPath = codexDir.appendingPathComponent("state_5.sqlite").path
        var db: OpaquePointer?
        if sqlite3_open(dbPath, &db) == SQLITE_OK {
            var stmt: OpaquePointer?
            let updateSQL = "UPDATE threads SET source = 'vscode' WHERE id = ?;"
            if sqlite3_prepare_v2(db, updateSQL, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_text(stmt, 1, (sessionId as NSString).utf8String, -1, nil)
                sqlite3_step(stmt)
            }
            sqlite3_finalize(stmt)
            sqlite3_close(db)
        }
        
        print("✅ [SilentAPIDispatcher] 已成功将新会话 \(sessionId) 注册到 Codex 桌面客户端侧边栏索引中")
    }
    
    /// 触发官方 codex://threads/<ID> 协议，驱动运行中的 Codex 窗口免重启即时刷新并定位会话
    private func notifyCodexGUIToRefresh(sessionId: String) {
        DispatchQueue.main.async {
            if let url = URL(string: "codex://threads/\(sessionId)") {
                NSWorkspace.shared.open(url)
                print("⚡️ [SilentAPIDispatcher] 已通过 codex://threads/\(sessionId) 驱动 Codex 客户端即时刷新")
            }
        }
    }
}
