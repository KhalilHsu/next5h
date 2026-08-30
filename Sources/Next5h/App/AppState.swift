import Foundation
import Combine

public enum NavigationTab: String, CaseIterable, Identifiable {
    case composer = "composer"
    case queue = "queue"
    case dashboard = "dashboard"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .composer: return "任务编排"
        case .queue: return "调度队列"
        case .dashboard: return "额度仪表盘"
        }
    }
    
    public var iconName: String {
        switch self {
        case .composer: return "square.and.pencil"
        case .queue: return "list.bullet.rectangle"
        case .dashboard: return "gauge.with.needle"
        }
    }
    
    /// 工作区主列表（只保留核心任务管理，仪表盘下沉至左下角卡片入口）
    public static var sidebarWorkspaceTabs: [NavigationTab] {
        return [.composer, .queue]
    }
}

public final class AppState: ObservableObject {
    public static let shared = AppState()
    
    @Published public var selectedTab: NavigationTab = .composer
    @Published public var editingJob: ScheduledJob? = nil
    
    private init() {}
}
