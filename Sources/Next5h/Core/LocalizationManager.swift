import Foundation
import Combine

public enum AppLanguage: String, CaseIterable, Identifiable {
    case zh = "zh"
    case en = "en"
    case ja = "ja"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .zh: return "中文"
        case .en: return "English"
        case .ja: return "日本語"
        }
    }
}

public final class LocalizationManager: ObservableObject {
    public static let shared = LocalizationManager()
    
    public static let userDefaultsKey = "next5h_app_language"
    
    @Published public private(set) var currentLanguage: AppLanguage
    
    private init() {
        if let saved = UserDefaults.standard.string(forKey: Self.userDefaultsKey),
           let lang = AppLanguage(rawValue: saved) {
            self.currentLanguage = lang
        } else {
            // 首次启动智能探测：中文->zh，日语->ja，其余一律以英文兜底
            let systemPreferred = Locale.preferredLanguages.first?.lowercased() ?? ""
            if systemPreferred.hasPrefix("zh") {
                self.currentLanguage = .zh
            } else if systemPreferred.hasPrefix("ja") {
                self.currentLanguage = .ja
            } else {
                self.currentLanguage = .en
            }
            UserDefaults.standard.set(self.currentLanguage.rawValue, forKey: Self.userDefaultsKey)
        }
    }
    
    public func setLanguage(_ language: AppLanguage) {
        guard language != currentLanguage else { return }
        self.currentLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: Self.userDefaultsKey)
    }
}

/// 集中式多语言文本映射仓库，支持任意多语种扩展
public enum L10n {
    /// 统一的多语言调度函数，自带英文全局兜底能力，可随未来需求无缝添加法语、德语等
    public static func tr(zh: String, en: String, ja: String? = nil, fr: String? = nil) -> String {
        switch LocalizationManager.shared.currentLanguage {
        case .zh: return zh
        case .en: return en
        case .ja: return ja ?? en
        }
    }
    
    // MARK: - 导航与顶栏
    public static var tabPending: String { tr(zh: "待发消息", en: "Pending", ja: "送信待ち") }
    public static var tabHistory: String { tr(zh: "消息历史", en: "History", ja: "送信履歴") }
    public static var tabDashboard: String { tr(zh: "额度看板", en: "Quota", ja: "クォータ監視") }
    
    // MARK: - 状态栏菜单
    public static var menuOpenWorkbench: String { tr(zh: "🖥️ 打开 Next5h 工作台", en: "🖥️ Open Next5h Workbench", ja: "🖥️ Next5h ワークベンチを開く") }
    public static var menuQuota5h: String { tr(zh: "🟢 5H 剩余:", en: "🟢 5H Remaining:", ja: "🟢 5H 残量:") }
    public static var menuQuotaWeekly: String { tr(zh: "🔵 周额度剩余:", en: "🔵 Weekly Remaining:", ja: "🔵 週間残量:") }
    public static var menuUnrestricted: String { tr(zh: "未受限", en: "Unrestricted", ja: "制限なし") }
    public static var menuResetAt: String { tr(zh: "重置:", en: "Resets:", ja: "リセット:") }
    public static var menuRefreshQuota: String { tr(zh: "🔄 立即刷新额度", en: "🔄 Refresh Quota Now", ja: "🔄 クォータ情報を更新") }
    public static var menuLanguageSubmenu: String { tr(zh: "🌐 语言 / Language", en: "🌐 Language / 言語", ja: "🌐 言語 / Language") }
    public static var menuQuit: String { tr(zh: "退出 Next5h", en: "Quit Next5h", ja: "Next5h を終了") }
    
    // MARK: - 待发消息列表 (QueueListView)
    public static var queueTitle: String { tr(zh: "待发消息", en: "Pending Messages", ja: "送信待ちメッセージ") }
    public static var queueSubtitle: String {
        tr(zh: "到点自动唤醒 Mac 并在后台向本地 Codex 客户端派发消息",
           en: "Wakes Mac on schedule and dispatches messages to local Codex client",
           ja: "指定時刻にMacを自動起動し、バックグラウンドでCodexにメッセージを送信します")
    }
    public static func queuePendingCount(_ count: Int) -> String {
        tr(zh: "\(count) 项待发送", en: "\(count) Pending", ja: "\(count) 件 送信待ち")
    }
    public static var queueNewMessage: String { tr(zh: "新建消息", en: "New Message", ja: "新規メッセージ") }
    public static var queueEmptyTitle: String { tr(zh: "当前暂无待发送消息", en: "No Pending Messages", ja: "送信待ちメッセージはありません") }
    public static var queueEmptySubtitle: String {
        tr(zh: "您可以创建早晨定时打卡、5H 额度解封自动发送或延时问询等任务。",
           en: "You can schedule morning check-ins, auto-send on quota reset, or delayed queries.",
           ja: "毎朝の定期連絡や、5Hクォータ復活時の自動送信、遅延タスクなどを設定できます。")
    }
    
    // MARK: - 任务卡片与状态
    public static var statusPending: String { tr(zh: "等待触发", en: "Pending", ja: "待機中") }
    public static var statusWaitingForQuota: String { tr(zh: "等待额度", en: "Waiting for Quota", ja: "クォータ待ち") }
    public static var statusRunning: String { tr(zh: "发送中", en: "Sending", ja: "送信中") }
    public static var statusSucceeded: String { tr(zh: "已完成", en: "Completed", ja: "完了") }
    public static var statusFailed: String { tr(zh: "失败", en: "Failed", ja: "失敗") }
    public static var statusCancelled: String { tr(zh: "已取消", en: "Cancelled", ja: "キャンセル済み") }
    
    public static var actionSendNow: String { tr(zh: "立即发送", en: "Send Now", ja: "今すぐ送信") }
    public static var actionEdit: String { tr(zh: "编辑", en: "Edit", ja: "編集") }
    public static var actionDelete: String { tr(zh: "删除", en: "Delete", ja: "削除") }
    public static var targetDestinationLabel: String { tr(zh: "目标", en: "Target", ja: "送信先") }
    public static var triggerStrategyLabel: String { tr(zh: "触发", en: "Trigger", ja: "トリガー") }
    
    public static var dateToday: String { tr(zh: "今天", en: "Today", ja: "今日") }
    public static var dateTomorrow: String { tr(zh: "明天", en: "Tomorrow", ja: "明日") }
    public static var dateYesterday: String { tr(zh: "昨天", en: "Yesterday", ja: "昨日") }
    
    // MARK: - 休眠提示 Banner
    public static var powerTipTitle: String {
        tr(zh: "Mac 纯合盖且未接显示器时，受系统固件限制无法联网唤醒。",
           en: "When Mac lid is closed without external display, macOS prevents network wake.",
           ja: "ディスプレイ非接続で画面を閉じている場合、macOSの仕様によりネットワーク復帰できません。")
    }
    public static var powerTipAction: String {
        tr(zh: "查看锁屏与休眠派发指南 →",
           en: "View Sleep & Lock Screen Guidelines →",
           ja: "スリープ＆画面ロック復帰ガイドを表示 →")
    }
    
    // MARK: - 消息历史 (HistoryListView)
    public static var historyTitle: String { tr(zh: "消息历史", en: "Message History", ja: "送信履歴") }
    public static var historySubtitle: String {
        tr(zh: "自动记录每次消息派发结果、耗时、模型参数与目标会话",
           en: "Automatically logs dispatch results, latency, model parameters, and target sessions",
           ja: "メッセージの送信結果、所要時間、モデルパラメータ、対象セッションを自動記録します")
    }
    public static func historyTotalCount(_ count: Int) -> String {
        tr(zh: "累计 \(count) 次", en: "Total: \(count)", ja: "累計 \(count) 件")
    }
    public static var historyClearAll: String { tr(zh: "清空历史", en: "Clear History", ja: "履歴を消去") }
    public static var historyFilterAll: String { tr(zh: "全部", en: "All", ja: "すべて") }
    public static var historyFilterSuccess: String { tr(zh: "成功", en: "Success", ja: "成功") }
    public static var historyFilterFailure: String { tr(zh: "失败", en: "Failure", ja: "失敗") }
    public static var historyTodaySuccess: String { tr(zh: "今日成功:", en: "Today's Success:", ja: "本日の成功:") }
    public static var historySuccessRate: String { tr(zh: "整体成功率:", en: "Overall Success:", ja: "全体の成功率:") }
    public static var historyAvgDuration: String { tr(zh: "平均耗时:", en: "Avg Latency:", ja: "平均所要時間:") }
    public static var historyEmptyTitle: String { tr(zh: "暂无消息发送记录", en: "No Message History", ja: "送信履歴はありません") }
    public static var historyEmptySubtitle: String {
        tr(zh: "排定任务在到点自动派发后，完整的执行流水与响应耗时将在此呈现。",
           en: "Execution logs and response times will appear here after scheduled messages are dispatched.",
           ja: "スケジュールメッセージが送信されると、実行履歴と所要時間がここに表示されます。")
    }
    public static var historyClearConfirmTitle: String { tr(zh: "清空发送历史", en: "Clear Message History", ja: "送信履歴の消去") }
    public static var historyClearConfirmMessage: String {
        tr(zh: "确定要清空全部消息发送记录吗？此操作无法撤销。",
           en: "Are you sure you want to clear all message logs? This cannot be undone.",
           ja: "すべてのメッセージ送信履歴を消去してもよろしいですか？この操作は取り消せません。")
    }
    public static var confirmClear: String { tr(zh: "清空", en: "Clear", ja: "消去") }
    public static var cancel: String { tr(zh: "取消", en: "Cancel", ja: "キャンセル") }
    
    // MARK: - 额度看板 (QuotaDashboardView)
    public static var dashboardTitle: String { tr(zh: "5H 与周额度监控看板", en: "5H & Weekly Quota Dashboard", ja: "5時間＆週間クォータ監視") }
    public static var dashboardSubtitle: String {
        tr(zh: "直连 OpenAI 官方接口实时探活与滑动窗口用量监测",
           en: "Live probing and sliding window monitoring via OpenAI APIs",
           ja: "OpenAI公式APIに直接接続し、スライディングウィンドウの利用状況をリアルタイム監視")
    }
    public static var dashboardRefresh: String { tr(zh: "立即刷新", en: "Refresh", ja: "今すぐ更新") }
    public static var dashboardSyncing: String { tr(zh: "同步中...", en: "Syncing...", ja: "同期中...") }
    public static func dashboardConnectedChatGPT(pid: Int32) -> String {
        tr(zh: "已连接本地 ChatGPT 客户端 (PID: \(pid))",
           en: "Connected to local ChatGPT app (PID: \(pid))",
           ja: "ローカル ChatGPT アプリに接続済み (PID: \(pid))")
    }
    public static var dashboardChatGPTNotRunning: String {
        tr(zh: "本地 ChatGPT.app 未运行 (无影响，Next5h 通过底层 Token 独立监控与派发)",
           en: "Local ChatGPT.app not running (Next5h monitors & dispatches independently)",
           ja: "ChatGPT.app は未起動です (Next5h はトークンにより独立して監視・送信を行います)")
    }
    public static var dashboard5hCardTitle: String { tr(zh: "5 小时滑动周期窗口 (300m)", en: "5-Hour Sliding Window (300m)", ja: "5時間ローリングウィンドウ (300分)") }
    public static func dashboard5hUsage(remaining: Double, used: Double) -> String {
        tr(zh: "当前剩余 \(String(format: "%.1f", remaining))% · 已用 \(String(format: "%.1f", used))%",
           en: "Remaining \(String(format: "%.1f", remaining))% · Used \(String(format: "%.1f", used))%",
           ja: "残り \(String(format: "%.1f", remaining))% · 使用済み \(String(format: "%.1f", used))%")
    }
    public static func dashboardRemaining(percent: Double) -> String {
        tr(zh: "剩余 \(String(format: "%.1f", percent))%",
           en: "\(String(format: "%.1f", percent))% Left",
           ja: "残り \(String(format: "%.1f", percent))%")
    }
    public static var dashboardResetsAt: String { tr(zh: "解锁时间 (Resets At)", en: "Resets At", ja: "リセット日時 (Resets At)") }
    public static var dashboardCountdown: String { tr(zh: "等待解锁倒计时", en: "Countdown to Reset", ja: "リセットまでの残り時間") }
    public static var dashboardReady: String { tr(zh: "就绪 (随时可用)", en: "Ready (Available)", ja: "利用可能") }
    
    public static var dashboardWeeklyCardTitle: String { tr(zh: "7 天周期总限额 (周额度)", en: "7-Day Weekly Limit (Weekly Quota)", ja: "7日間週間利用枠 (週クォータ)") }
    public static func dashboardWeeklyUsage(remaining: Double, used: Double) -> String {
        tr(zh: "周剩余 \(String(format: "%.1f", remaining))% · 已用 \(String(format: "%.1f", used))%",
           en: "Weekly Remaining \(String(format: "%.1f", remaining))% · Used \(String(format: "%.1f", used))%",
           ja: "週残り \(String(format: "%.1f", remaining))% · 使用済み \(String(format: "%.1f", used))%")
    }
    public static var dashboardWeeklyReset: String { tr(zh: "周额度重置", en: "Weekly Reset", ja: "週間リセット日時") }
    public static var dashboardWeeklyResetRemaining: String { tr(zh: "重置倒计时", en: "Reset Countdown", ja: "リセットまでの時間") }
    public static var dashboardAlwaysAvailable: String { tr(zh: "永久有效 / 未限制", en: "Unrestricted", ja: "無制限") }
    
    // MARK: - 任务编排/编辑 Sheet (JobEditorSheetView)
    public static var editorNewTitle: String { tr(zh: "新建定时消息", en: "New Scheduled Message", ja: "定期メッセージ作成") }
    public static var editorEditTitle: String { tr(zh: "编辑消息", en: "Edit Message", ja: "メッセージ編集") }
    public static var editorNewSubtitle: String {
        tr(zh: "配置到点自动派发至本地 Codex 客户端的消息内容与参数",
           en: "Configure message content and parameters to auto-send to local Codex",
           ja: "指定時刻にローカルCodexへ自動送信するプロンプトとパラメータを設定")
    }
    public static var editorEditSubtitle: String {
        tr(zh: "修改已排定消息的执行参数与 Prompt 内容",
           en: "Edit scheduled message parameters and prompt",
           ja: "スケジュール済みメッセージのパラメータとプロンプトを変更")
    }
    public static var editorTemplatesTitle: String { tr(zh: "⚡️ 快捷模板填入 (可选)", en: "⚡️ Quick Templates (Optional)", ja: "⚡️ クイックテンプレート (任意)") }
    public static var templateDailyMorning: String { tr(zh: "🌅 每日早晨打卡", en: "🌅 Daily Morning Check-in", ja: "🌅 毎朝の定期連絡") }
    public static var templateQuotaReset: String { tr(zh: "⚡️ 5H 解封自动发", en: "⚡️ Auto-send on 5H Reset", ja: "⚡️ 5H枠復活時に自動送信") }
    public static var templateDeepQuery: String { tr(zh: "☕️ 延时深度问询", en: "☕️ Delayed Deep Query", ja: "☕️ 3時間後まとめ通知") }
    
    public static var editorMessageTitleField: String { tr(zh: "消息标题", en: "Message Title", ja: "メッセージタイトル") }
    public static var editorMessageTitlePlaceholder: String { tr(zh: "例如：晨间打卡 / 项目复盘", en: "e.g., Morning Check-in / Code Review", ja: "例: 毎朝の挨拶 / コードレビュー") }
    public static var editorPromptField: String { tr(zh: "消息内容 (Prompt)", en: "Message Content (Prompt)", ja: "プロンプト内容 (User Query)") }
    public static var editorPromptPlaceholder: String { tr(zh: "输入将派发给 Codex 的具体指令或问题...", en: "Enter prompt to dispatch to Codex...", ja: "Codexに送信する指示や質問を入力...") }
    public static var editorModelSection: String { tr(zh: "模型与思考强度", en: "Model & Reasoning Effort", ja: "モデル＆推論レベル") }
    public static var editorDestinationSection: String { tr(zh: "目标项目与会话", en: "Destination & Session", ja: "送信先プロジェクト＆セッション") }
    public static var editorScheduleSection: String { tr(zh: "定时触发策略", en: "Trigger Schedule", ja: "トリガー条件") }
    public static var editorDispatchModeSection: String { tr(zh: "派发通道模式", en: "Dispatch Mode", ja: "送信モード") }
    public static var editorSaveButton: String { tr(zh: "保存并排定", en: "Save & Schedule", ja: "保存してスケジュール") }
}
