import Foundation
import Combine

public enum NavigationTab: String, CaseIterable, Identifiable {
    case composer = "composer"
    case queue = "queue"
    case history = "history"
    case dashboard = "dashboard"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .composer: return "任务编排"
        case .queue: return "调度队列"
        case .history: return "历史发送"
        case .dashboard: return "额度仪表盘"
        }
    }
    
    public var iconName: String {
        switch self {
        case .composer: return "square.and.pencil"
        case .queue: return "list.bullet.rectangle"
        case .history: return "clock.arrow.circlepath"
        case .dashboard: return "gauge.with.needle"
        }
    }
    
    /// 工作区主列表（任务编排、调度队列、历史发送）
    public static var sidebarWorkspaceTabs: [NavigationTab] {
        return [.composer, .queue, .history]
    }
}

public final class AppState: ObservableObject {
    public static let shared = AppState()
    
    @Published public var selectedTab: NavigationTab = .composer
    @Published public var editingJob: ScheduledJob? = nil
    
    private init() {}
}
