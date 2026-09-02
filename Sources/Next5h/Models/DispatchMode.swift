import Foundation

public enum DispatchMode: String, Codable, CaseIterable, Identifiable {
    case silentAPI = "silent_api"
    case foregroundUI = "foreground_ui"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        let isZh = LocalizationManager.shared.currentLanguage == .zh
        switch self {
        case .silentAPI: return isZh ? "静默后台发送 (推荐)" : "Silent Background (Recommended)"
        case .foregroundUI: return isZh ? "呼出 ChatGPT 窗口" : "Foreground Window"
        }
    }
    
    public var detailDescription: String {
        let isZh = LocalizationManager.shared.currentLanguage == .zh
        switch self {
        case .silentAPI:
            return isZh ? "纯后台提交会话，不抢键盘焦点、不弹窗打扰，发完弹系统通知"
                        : "Submits in background via CLI without focus interruption; notifies on completion"
        case .foregroundUI:
            return isZh ? "到点自动唤醒本地 ChatGPT 客户端并聚焦输入框，适合实时查看 AI 回复"
                        : "Wakes local ChatGPT app and focuses input box; best for live viewing of responses"
        }
    }
    
    public var iconName: String {
        switch self {
        case .silentAPI: return "bolt.shield.fill"
        case .foregroundUI: return "macwindow"
        }
    }
}
