import Foundation
import Combine

public enum NavigationTab: String, CaseIterable, Identifiable {
    case queue = "queue"
    case history = "history"
    case dashboard = "dashboard"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .queue: return L10n.tabPending
        case .history: return L10n.tabHistory
        case .dashboard: return L10n.tabDashboard
        }
    }
    
    public var iconName: String {
        switch self {
        case .queue: return "list.bullet.rectangle"
        case .history: return "clock.arrow.circlepath"
        case .dashboard: return "gauge.with.needle"
        }
    }
}

public final class AppState: ObservableObject {
    public static let shared = AppState()
    
    @Published public var selectedTab: NavigationTab = .queue
    
    // Sheet 弹窗编排/编辑状态
    @Published public var isShowingJobSheet: Bool = false
    @Published public var editingJob: ScheduledJob? = nil
    
    private init() {}
    
    /// 呼出新建任务 Sheet 弹窗
    public func openNewJobSheet() {
        self.editingJob = nil
        self.isShowingJobSheet = true
    }
    
    /// 呼出编辑现有任务 Sheet 弹窗
    public func openEditJobSheet(job: ScheduledJob) {
        self.editingJob = job
        self.isShowingJobSheet = true
    }
    
    /// 关闭 Sheet 弹窗
    public func closeJobSheet() {
        self.isShowingJobSheet = false
        self.editingJob = nil
    }
}
