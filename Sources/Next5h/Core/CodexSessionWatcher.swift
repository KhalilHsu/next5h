import Foundation
import SQLite3

public struct CodexActivitySnapshot: Equatable {
    public let latestStartedAt: Int64
    public let latestCompletedAt: Int64
    public let hasActiveTurn: Bool
    public let latestActivityTime: Date
    
    public var isActiveOrWithin10Minutes: Bool {
        if hasActiveTurn { return true }
        let nowSec = Int64(Date().timeIntervalSince1970)
        let mostRecent = max(latestStartedAt, latestCompletedAt)
        guard mostRecent > 0 else { return false }
        return (nowSec - mostRecent) < 600 // 10 分钟内 (600秒)
    }
}

public final class CodexSessionWatcher: @unchecked Sendable {
    public static let shared = CodexSessionWatcher()
    
    private let dbPath: String
    private var lastSeenStartedAt: Int64 = 0
    private var lastSeenCompletedAt: Int64 = 0
    private var checkTimer: Timer?
    private var isStarted: Bool = false
    
    private init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        self.dbPath = home.appendingPathComponent(".codex/thread_history_1.sqlite").path
    }
    
    public func start() {
        guard !isStarted else { return }
        isStarted = true
        
        // 初始抓取当前基准水位，避免启动瞬间误报
        let initial = queryActivitySnapshot()
        self.lastSeenStartedAt = initial.latestStartedAt
        self.lastSeenCompletedAt = initial.latestCompletedAt
        
        // 本地每 2.5 秒轻量检测一次本地 SQLite (耗时 < 1ms，纯本地查询无网络开销)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.checkTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
                DispatchQueue.global(qos: .utility).async {
                    self?.checkActivity()
                }
            }
        }
    }
    
    public func queryActivitySnapshot() -> CodexActivitySnapshot {
        var db: OpaquePointer?
        guard sqlite3_open_v2(dbPath, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            return CodexActivitySnapshot(
                latestStartedAt: 0,
                latestCompletedAt: 0,
                hasActiveTurn: false,
                latestActivityTime: Date(timeIntervalSince1970: 0)
            )
        }
        defer { sqlite3_close(db) }
        
        // 过滤掉超过 24 小时的脏 inProgress 记录，只查近期真正活跃的 turn
        let query = """
        SELECT 
            COALESCE(MAX(started_at), 0),
            COALESCE(MAX(completed_at), 0),
            (SELECT COUNT(*) FROM thread_turns WHERE status = 'inProgress' AND started_at > strftime('%s', 'now') - 3600)
        FROM thread_turns;
        """
        
        var stmt: OpaquePointer?
        var startedAt: Int64 = 0
        var completedAt: Int64 = 0
        var activeCount: Int = 0
        
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_ROW {
                startedAt = sqlite3_column_int64(stmt, 0)
                completedAt = sqlite3_column_int64(stmt, 1)
                activeCount = Int(sqlite3_column_int(stmt, 2))
            }
        }
        sqlite3_finalize(stmt)
        
        let mostRecent = max(startedAt, completedAt)
        return CodexActivitySnapshot(
            latestStartedAt: startedAt,
            latestCompletedAt: completedAt,
            hasActiveTurn: activeCount > 0,
            latestActivityTime: Date(timeIntervalSince1970: Double(mostRecent))
        )
    }
    
    private func checkActivity() {
        let snapshot = queryActivitySnapshot()
        
        // 1. 检测 Session 是否刚开始
        if snapshot.latestStartedAt > lastSeenStartedAt {
            lastSeenStartedAt = snapshot.latestStartedAt
            DispatchQueue.main.async {
                QuotaProbeEngine.shared.addLog(
                    zh: "⚡️ 检测到本地 CLI/客户端新会话已开始，激活 10 分钟高频追踪模式 (每 1 分钟刷新)",
                    en: "⚡️ Local CLI/client session started, activating 10-min high-frequency tracking (1m interval)",
                    ja: "⚡️ ローカルCLI/セッション開始を検知、高頻度追跡モード（1分間隔）を有効化"
                )
                QuotaProbeEngine.shared.refreshNow()
            }
        }
        
        // 2. 检测 Session 是否刚结束
        if snapshot.latestCompletedAt > lastSeenCompletedAt {
            lastSeenCompletedAt = snapshot.latestCompletedAt
            DispatchQueue.main.async {
                QuotaProbeEngine.shared.addLog(
                    zh: "🎯 检测到本地 CLI/客户端会话已结束，立即同步最新消耗额度",
                    en: "🎯 Local CLI/client session completed, syncing latest quota usage",
                    ja: "🎯 ローカルCLI/セッション終了を検知、最新クォータを即時同期"
                )
                QuotaProbeEngine.shared.refreshNow()
            }
        }
    }
    
    /// 当前建议的额度轮询间隔
    public var currentRecommendedInterval: TimeInterval {
        let snapshot = queryActivitySnapshot()
        
        // 活跃期：当前有会话进行中，或最近 10 分钟内有会话活跃
        if snapshot.isActiveOrWithin10Minutes {
            return 60 // 1 分钟高频
        }
        
        // 空闲期
        let remaining = QuotaProbeEngine.shared.currentQuota.remainingSeconds
        if remaining > 0 && remaining <= 600 {
            return 180 // 临近解锁 10 分钟内：3 分钟探测
        }
        return 300 // 常规空闲：5 分钟巡航（告别原先死板的 30 分钟）
    }
    
    /// 是否正处于 10 分钟活跃窗口内
    public var isInActiveBurstWindow: Bool {
        return queryActivitySnapshot().isActiveOrWithin10Minutes
    }
}
