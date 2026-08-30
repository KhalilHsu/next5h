import Foundation
import AppKit
import SQLite3

public struct LiveQuotaResponse: Codable {
    public struct RateLimit: Codable {
        public struct Window: Codable {
            public var used_percent: Double
            public var limit_window_seconds: Int
            public var reset_after_seconds: Double
            public var reset_at: Double
        }
        public var allowed: Bool
        public var limit_reached: Bool
        public var primary_window: Window?
        public var secondary_window: Window?
    }
    public var user_id: String?
    public var email: String?
    public var plan_type: String?
    public var rate_limit: RateLimit?
}

public final class LocalCodexContextReader {
    public static let shared = LocalCodexContextReader()
    
    private let codexHomeDir: URL
    
    private init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        self.codexHomeDir = home.appendingPathComponent(".codex")
    }
    
    /// 读取本地 ~/.codex/auth.json 中的 Access Token
    public func getLocalAccessToken() -> String? {
        let authURL = codexHomeDir.appendingPathComponent("auth.json")
        guard let data = try? Data(contentsOf: authURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tokens = json["tokens"] as? [String: Any],
              let accessToken = tokens["access_token"] as? String,
              !accessToken.isEmpty else {
            return nil
        }
        return accessToken
    }
    
    /// 直连官方后端实时查询 5H 与每周实时额度
    public func fetchLiveQuota() async -> QuotaSnapshot? {
        guard let token = getLocalAccessToken() else {
            print("⚠️ [LocalCodexContextReader] 未在 ~/.codex/auth.json 中找到有效 token")
            return nil
        }
        
        guard let url = URL(string: "https://chatgpt.com/backend-api/wham/usage") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("CodexBrowser/151.0.7922.174", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10.0
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 else {
                print("⚠️ [LocalCodexContextReader] 接口返回状态码非 200")
                return nil
            }
            
            let decoded = try JSONDecoder().decode(LiveQuotaResponse.self, from: data)
            let primary = decoded.rate_limit?.primary_window
            let secondary = decoded.rate_limit?.secondary_window
            
            let primaryResetDate: Date? = primary != nil ? Date(timeIntervalSince1970: primary!.reset_at) : nil
            let weeklyResetDate: Date? = secondary != nil ? Date(timeIntervalSince1970: secondary!.reset_at) : nil
            
            let (isRunning, pid) = checkRunningChatGPTApp()
            
            let emailInfo = decoded.email ?? "Plus 用户"
            let planInfo = decoded.plan_type?.uppercased() ?? "PLUS"
            
            return QuotaSnapshot(
                usedPercent: primary?.used_percent ?? 0.0,
                resetsAt: primaryResetDate,
                windowMinutes: (primary?.limit_window_seconds ?? 18000) / 60,
                weeklyUsedPercent: secondary?.used_percent,
                weeklyResetsAt: weeklyResetDate,
                capturedAt: Date(),
                isConnectedToChatGPTApp: isRunning,
                chatGPTPid: pid,
                statusDescription: "\(emailInfo) (\(planInfo)) · 5H用量 \(Int(primary?.used_percent ?? 0))%"
            )
        } catch {
            print("⚠️ [LocalCodexContextReader] 请求 live quota 失败: \(error)")
            return nil
        }
    }
    
    /// 读取本地 ~/.codex/models_cache.json 中的真实动态模型列表
    public func fetchLiveModels() -> [DynamicCodexModel] {
        return ModelCatalogService.shared.availableModels
    }
    
    /// 从 ~/.codex/state_5.sqlite 精准读取真实项目和严格按项目分类的会话
    public func fetchCategorizedProjectsAndSessions() -> (projects: [CodexProject], noProjectSessions: [CodexSession]) {
        let dbPath = codexHomeDir.appendingPathComponent("state_5.sqlite").path
        var db: OpaquePointer?
        
        guard sqlite3_open_v2(dbPath, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            return ([], [])
        }
        defer { sqlite3_close(db) }
        
        // 1. 读取项目与对应根路径
        var projectsMap: [String: (name: String, roots: [String], sessions: [CodexSession])] = [:]
        let projQuery = "SELECT p.id, p.name, pr.path FROM projects p LEFT JOIN project_roots pr ON p.id = pr.project_id;"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, projQuery, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                let id = String(cString: sqlite3_column_text(stmt, 0))
                let name = String(cString: sqlite3_column_text(stmt, 1))
                let root = sqlite3_column_text(stmt, 2).map { String(cString: $0) }
                
                if var existing = projectsMap[id] {
                    if let r = root, !existing.roots.contains(r) {
                        existing.roots.append(r)
                    }
                    projectsMap[id] = existing
                } else {
                    projectsMap[id] = (name: name, roots: root != nil ? [root!] : [], sessions: [])
                }
            }
        }
        sqlite3_finalize(stmt)
        
        // 2. 读取全部真实会话并根据 project_id 或 cwd 严格分类
        var noProjSessions: [CodexSession] = []
        let threadQuery = "SELECT id, project_id, title, name, cwd, updated_at FROM threads ORDER BY updated_at DESC;"
        
        if sqlite3_prepare_v2(db, threadQuery, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                let id = String(cString: sqlite3_column_text(stmt, 0))
                let pid = sqlite3_column_text(stmt, 1).map { String(cString: $0) }
                let title = sqlite3_column_text(stmt, 2).map { String(cString: $0) }
                let name = sqlite3_column_text(stmt, 3).map { String(cString: $0) }
                let cwd = sqlite3_column_text(stmt, 4).map { String(cString: $0) } ?? ""
                let updatedAtSec = sqlite3_column_int64(stmt, 5)
                
                let sessionTitle = title ?? name ?? "未命名会话"
                // 忽略内部提示词会话
                if sessionTitle.starts(with: "The following is the Codex") || sessionTitle.starts(with: "# Files mentioned") {
                    continue
                }
                
                // 严格匹配归属项目
                var matchedProjectId: String? = nil
                if let pid = pid, projectsMap[pid] != nil {
                    matchedProjectId = pid
                } else {
                    for (pId, pInfo) in projectsMap {
                        for root in pInfo.roots {
                            if !root.isEmpty && cwd.starts(with: root) {
                                matchedProjectId = pId
                                break
                            }
                        }
                        if matchedProjectId != nil { break }
                    }
                }
                
                let session = CodexSession(
                    id: id,
                    title: sessionTitle,
                    updatedAt: Date(timeIntervalSince1970: Double(updatedAtSec)),
                    projectId: matchedProjectId,
                    isLocalDetected: true
                )
                
                if let mId = matchedProjectId, var pInfo = projectsMap[mId] {
                    pInfo.sessions.append(session)
                    projectsMap[mId] = pInfo
                } else {
                    noProjSessions.append(session)
                }
            }
        }
        sqlite3_finalize(stmt)
        
        let projects = projectsMap.map { (id, val) in
            CodexProject(id: id, name: val.name, description: val.roots.joined(separator: ", "), sessions: val.sessions)
        }.sorted { $0.name < $1.name }
        
        return (projects, noProjSessions)
    }
    
    /// 检查本地 ChatGPT.app 是否正在运行
    public func checkRunningChatGPTApp() -> (isRunning: Bool, pid: Int32?) {
        let apps = NSRunningApplication.runningApplications(withBundleIdentifier: "com.openai.codex")
            + NSRunningApplication.runningApplications(withBundleIdentifier: "com.openai.chat")
        
        if let app = apps.first {
            return (true, app.processIdentifier)
        }
        return (false, nil)
    }
}
