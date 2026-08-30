import Foundation

public enum DispatchMode: String, Codable, CaseIterable, Identifiable {
    case silentAPI = "silent_api"
    case foregroundUI = "foreground_ui"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .silentAPI: return "静默后台发送 (推荐)"
        case .foregroundUI: return "呼出 ChatGPT 窗口"
        }
    }
    
    public var detailDescription: String {
        switch self {
        case .silentAPI: return "纯后台提交会话，不抢键盘焦点、不弹窗打扰，发完弹系统通知"
        case .foregroundUI: return "到点自动唤醒本地 ChatGPT 客户端并聚焦输入框，适合实时查看 AI 回复"
        }
    }
    
    public var iconName: String {
        switch self {
        case .silentAPI: return "bolt.shield.fill"
        case .foregroundUI: return "macwindow"
        }
    }
}
