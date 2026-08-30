import Foundation
import AppKit
import SQLite3

public final class SilentAPIDispatcher {
    public static let shared = SilentAPIDispatcher()
    
    private let codexBinaryPath = "/Applications/ChatGPT.app/Contents/Resources/codex"
    
    private init() {}
    
    /// 执行后台真实静默发送至本地 Codex 引擎
    public func dispatch(job: ScheduledJob) async throws -> Bool {
        print("🚀 [SilentAPIDispatcher] 正在调用本地 Codex CLI 发送任务: \(job.title)")
        
        let modelSlug = job.model.slug
        let effortRaw = job.reasoningEffort.rawValue
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: codexBinaryPath)
        process.standardInput = FileHandle.nullDevice
        
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
                        if let match = output.range(of: "session id: ([0-9a-f\\-]+)", options: .regularExpression) {
                            let rawMatch = String(output[match])
                            let sessionId = rawMatch.replacingOccurrences(of: "session id: ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                            resolvedSessionId = sessionId
                            self.syncNewSessionToCodexGUI(sessionId: sessionId, title: job.prompt)
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
                            body: "已成功向本地 Codex 派发任务：\(job.title)"
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
