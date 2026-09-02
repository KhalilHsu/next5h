import Foundation
import Combine

public enum AppLanguage: String, CaseIterable, Identifiable {
    case zh = "zh"
    case en = "en"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .zh: return "中文"
        case .en: return "English"
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
            // 首次启动：读取系统语言，若是中文则用中文，其余一律以英文兜底
            let systemPreferred = Locale.preferredLanguages.first?.lowercased() ?? ""
            if systemPreferred.hasPrefix("zh") {
                self.currentLanguage = .zh
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

/// 集中式多语言文本映射仓库
public enum L10n {
    private static var isZh: Bool {
        LocalizationManager.shared.currentLanguage == .zh
    }
    
    // MARK: - 导航与顶栏
    public static var tabPending: String { isZh ? "待发消息" : "Pending" }
    public static var tabHistory: String { isZh ? "消息历史" : "History" }
    public static var tabDashboard: String { isZh ? "额度看板" : "Quota" }
    
    // MARK: - 状态栏菜单
    public static var menuOpenWorkbench: String { isZh ? "🖥️ 打开 Next5h 工作台" : "🖥️ Open Next5h Workbench" }
    public static var menuQuota5h: String { isZh ? "🟢 5H 剩余:" : "🟢 5H Remaining:" }
    public static var menuQuotaWeekly: String { isZh ? "🔵 周额度剩余:" : "🔵 Weekly Remaining:" }
    public static var menuUnrestricted: String { isZh ? "未受限" : "Unrestricted" }
    public static var menuResetAt: String { isZh ? "重置:" : "Resets:" }
    public static var menuRefreshQuota: String { isZh ? "🔄 立即刷新额度" : "🔄 Refresh Quota Now" }
    public static var menuLanguageSubmenu: String { isZh ? "🌐 语言 / Language" : "🌐 Language / 语言" }
    public static var menuQuit: String { isZh ? "退出 Next5h" : "Quit Next5h" }
    
    // MARK: - 待发消息列表 (QueueListView)
    public static var queueTitle: String { isZh ? "待发消息" : "Pending Messages" }
    public static var queueSubtitle: String {
        isZh ? "到点自动唤醒 Mac 并在后台向本地 Codex 客户端派发消息"
             : "Wakes Mac on schedule and dispatches messages to local Codex client"
    }
    public static func queuePendingCount(_ count: Int) -> String {
        isZh ? "\(count) 项待发送" : "\(count) Pending"
    }
    public static var queueNewMessage: String { isZh ? "新建消息" : "New Message" }
    public static var queueEmptyTitle: String { isZh ? "当前暂无待发送消息" : "No Pending Messages" }
    public static var queueEmptySubtitle: String {
        isZh ? "您可以创建早晨定时打卡、5H 额度解封自动发送或延时问询等任务。"
             : "You can schedule morning check-ins, auto-send on quota reset, or delayed queries."
    }
    
    // MARK: - 任务卡片与状态
    public static var statusPending: String { isZh ? "等待触发" : "Pending" }
    public static var statusWaitingForQuota: String { isZh ? "等待额度" : "Waiting for Quota" }
    public static var statusRunning: String { isZh ? "发送中" : "Sending" }
    public static var statusSucceeded: String { isZh ? "已完成" : "Completed" }
    public static var statusFailed: String { isZh ? "失败" : "Failed" }
    public static var statusCancelled: String { isZh ? "已取消" : "Cancelled" }
    
    public static var actionSendNow: String { isZh ? "立即发送" : "Send Now" }
    public static var actionEdit: String { isZh ? "编辑" : "Edit" }
    public static var actionDelete: String { isZh ? "删除" : "Delete" }
    public static var targetDestinationLabel: String { isZh ? "目标" : "Target" }
    public static var triggerStrategyLabel: String { isZh ? "触发" : "Trigger" }
    
    public static var dateToday: String { isZh ? "今天" : "Today" }
    public static var dateTomorrow: String { isZh ? "明天" : "Tomorrow" }
    
    // MARK: - 休眠提示 Banner
    public static var powerTipTitle: String {
        isZh ? "Mac 纯合盖且未接显示器时，受系统固件限制无法联网唤醒。"
             : "When Mac lid is closed without external display, macOS prevents network wake."
    }
    public static var powerTipAction: String {
        isZh ? "查看锁屏与休眠派发指南 →" : "View Sleep & Lock Screen Guidelines →"
    }
    
    // MARK: - 消息历史 (HistoryListView)
    public static var historyTitle: String { isZh ? "消息历史" : "Message History" }
    public static var historySubtitle: String {
        isZh ? "自动记录每次消息派发结果、耗时、模型参数与目标会话"
             : "Automatically logs dispatch results, latency, model parameters, and target sessions"
    }
    public static func historyTotalCount(_ count: Int) -> String {
        isZh ? "累计 \(count) 次" : "Total: \(count)"
    }
    public static var historyClearAll: String { isZh ? "清空历史" : "Clear History" }
    public static var historyFilterAll: String { isZh ? "全部" : "All" }
    public static var historyFilterSuccess: String { isZh ? "成功" : "Success" }
    public static var historyFilterFailure: String { isZh ? "失败" : "Failure" }
    public static var historyTodaySuccess: String { isZh ? "今日成功:" : "Today's Success:" }
    public static var historySuccessRate: String { isZh ? "整体成功率:" : "Overall Success:" }
    public static var historyAvgDuration: String { isZh ? "平均耗时:" : "Avg Latency:" }
    public static var historyEmptyTitle: String { isZh ? "暂无消息发送记录" : "No Message History" }
    public static var historyEmptySubtitle: String {
        isZh ? "排定任务在到点自动派发后，完整的执行流水与响应耗时将在此呈现。"
             : "Execution logs and response times will appear here after scheduled messages are dispatched."
    }
    public static var historyClearConfirmTitle: String { isZh ? "清空发送历史" : "Clear Message History" }
    public static var historyClearConfirmMessage: String {
        isZh ? "确定要清空全部消息发送记录吗？此操作无法撤销。"
             : "Are you sure you want to clear all message logs? This cannot be undone."
    }
    public static var confirmClear: String { isZh ? "清空" : "Clear" }
    public static var cancel: String { isZh ? "取消" : "Cancel" }
    
    // MARK: - 额度看板 (QuotaDashboardView)
    public static var dashboardTitle: String { isZh ? "5H 与周额度监控看板" : "5H & Weekly Quota Dashboard" }
    public static var dashboardSubtitle: String {
        isZh ? "直连 OpenAI 官方接口实时探活与滑动窗口用量监测"
             : "Live probing and sliding window monitoring via OpenAI APIs"
    }
    public static var dashboardRefresh: String { isZh ? "立即刷新" : "Refresh" }
    public static var dashboardSyncing: String { isZh ? "同步中..." : "Syncing..." }
    public static func dashboardConnectedChatGPT(pid: Int32) -> String {
        isZh ? "已连接本地 ChatGPT 客户端 (PID: \(pid))" : "Connected to local ChatGPT app (PID: \(pid))"
    }
    public static var dashboardChatGPTNotRunning: String {
        isZh ? "本地 ChatGPT.app 未运行 (无影响，Next5h 通过底层 Token 独立监控与派发)"
             : "Local ChatGPT.app not running (Next5h monitors & dispatches independently)"
    }
    public static var dashboard5hCardTitle: String { isZh ? "5 小时滑动周期窗口 (300m)" : "5-Hour Sliding Window (300m)" }
    public static func dashboard5hUsage(remaining: Double, used: Double) -> String {
        isZh ? "当前剩余 \(String(format: "%.1f", remaining))% · 已用 \(String(format: "%.1f", used))%"
             : "Remaining \(String(format: "%.1f", remaining))% · Used \(String(format: "%.1f", used))%"
    }
    public static func dashboardRemaining(percent: Double) -> String {
        isZh ? "剩余 \(String(format: "%.1f", percent))%" : "\(String(format: "%.1f", percent))% Left"
    }
    public static var dashboardResetsAt: String { isZh ? "解锁时间 (Resets At)" : "Resets At" }
    public static var dashboardCountdown: String { isZh ? "等待解锁倒计时" : "Countdown to Reset" }
    public static var dashboardReady: String { isZh ? "就绪 (随时可用)" : "Ready (Available)" }
    
    public static var dashboardWeeklyCardTitle: String { isZh ? "7 天周期总限额 (周额度)" : "7-Day Weekly Limit (Weekly Quota)" }
    public static func dashboardWeeklyUsage(remaining: Double, used: Double) -> String {
        isZh ? "周剩余 \(String(format: "%.1f", remaining))% · 已用 \(String(format: "%.1f", used))%"
             : "Weekly Remaining \(String(format: "%.1f", remaining))% · Used \(String(format: "%.1f", used))%"
    }
    public static var dashboardWeeklyReset: String { isZh ? "周额度重置" : "Weekly Reset" }
    public static var dashboardWeeklyResetRemaining: String { isZh ? "重置倒计时" : "Reset Countdown" }
    public static var dashboardAlwaysAvailable: String { isZh ? "永久有效 / 未限制" : "Unrestricted" }
    
    // MARK: - 任务编排/编辑 Sheet (JobEditorSheetView)
    public static var editorNewTitle: String { isZh ? "新建定时消息" : "New Scheduled Message" }
    public static var editorEditTitle: String { isZh ? "编辑消息" : "Edit Message" }
    public static var editorNewSubtitle: String {
        isZh ? "配置到点自动派发至本地 Codex 客户端的消息内容与参数"
             : "Configure message content and parameters to auto-send to local Codex"
    }
    public static var editorEditSubtitle: String {
        isZh ? "修改已排定消息的执行参数与 Prompt 内容"
             : "Edit scheduled message parameters and prompt"
    }
    public static var editorTemplatesTitle: String { isZh ? "⚡️ 快捷模板填入 (可选)" : "⚡️ Quick Templates (Optional)" }
    public static var templateDailyMorning: String { isZh ? "🌅 每日早晨打卡" : "🌅 Daily Morning Check-in" }
    public static var templateQuotaReset: String { isZh ? "⚡️ 5H 解封自动发" : "⚡️ Auto-send on 5H Reset" }
    public static var templateDeepQuery: String { isZh ? "☕️ 延时深度问询" : "☕️ Delayed Deep Query" }
    
    public static var editorMessageTitleField: String { isZh ? "消息标题" : "Message Title" }
    public static var editorMessageTitlePlaceholder: String { isZh ? "例如：晨间打卡 / 项目复盘" : "e.g., Morning Check-in / Code Review" }
    public static var editorPromptField: String { isZh ? "消息内容 (Prompt)" : "Message Content (Prompt)" }
    public static var editorPromptPlaceholder: String { isZh ? "输入将派发给 Codex 的具体指令或问题..." : "Enter prompt to dispatch to Codex..." }
    public static var editorModelSection: String { isZh ? "模型与思考强度" : "Model & Reasoning Effort" }
    public static var editorDestinationSection: String { isZh ? "目标项目与会话" : "Destination & Session" }
    public static var editorScheduleSection: String { isZh ? "定时触发策略" : "Trigger Schedule" }
    public static var editorDispatchModeSection: String { isZh ? "派发通道模式" : "Dispatch Mode" }
    public static var editorSaveButton: String { isZh ? "保存并排定" : "Save & Schedule" }
}
