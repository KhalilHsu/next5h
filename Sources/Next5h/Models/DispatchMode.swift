import Foundation

public enum DispatchMode: String, Codable, CaseIterable, Identifiable {
    case silentAPI = "silent_api"
    case foregroundUI = "foreground_ui"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .silentAPI:
            return L10n.tr(
                zh: "静默后台发送 (推荐)",
                en: "Silent Background (Recommended)",
                ja: "バックグラウンドサイレント送信 (推奨)"
            )
        case .foregroundUI:
            return L10n.tr(
                zh: "呼出 ChatGPT 窗口",
                en: "Foreground Window",
                ja: "ChatGPTウィンドウを前面表示"
            )
        }
    }
    
    public var detailDescription: String {
        switch self {
        case .silentAPI:
            return L10n.tr(
                zh: "纯后台提交会话，不抢键盘焦点、不弹窗打扰，发完弹系统通知",
                en: "Submits in background via CLI without focus interruption; notifies on completion",
                ja: "フォーカスを奪わず静かにバックグラウンド送信し、完了後に通知を表示します"
            )
        case .foregroundUI:
            return L10n.tr(
                zh: "到点自动唤醒本地 ChatGPT 客户端并聚焦输入框，适合实时查看 AI 回复",
                en: "Wakes local ChatGPT app and focuses input box; best for live viewing of responses",
                ja: "ChatGPTアプリを前面に表示して入力欄にフォーカスし、回答をリアルタイム確認できます"
            )
        }
    }
    
    public var iconName: String {
        switch self {
        case .silentAPI: return "bolt.shield.fill"
        case .foregroundUI: return "macwindow"
        }
    }
}
