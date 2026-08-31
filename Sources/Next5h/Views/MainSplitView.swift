import SwiftUI

public struct MainSplitView: View {
    @ObservedObject private var appState = AppState.shared
    @ObservedObject private var queueManager = JobQueueManager.shared
    @ObservedObject private var historyManager = DispatchHistoryManager.shared
    @ObservedObject private var quotaEngine = QuotaProbeEngine.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            Group {
                switch appState.selectedTab {
                case .queue:
                    QueueListView()
                case .history:
                    HistoryListView()
                case .dashboard:
                    QuotaDashboardView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 720, idealWidth: 840, maxWidth: .infinity, minHeight: 520, idealHeight: 620, maxHeight: .infinity)
        .toolbar {
            // 顶栏左侧：App 品牌与图标
            ToolbarItem(placement: .navigation) {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.badge.clock.fill")
                        .foregroundStyle(.orange)
                        .font(.title3)
                    Text("Next5h")
                        .font(.headline.bold())
                }
                .padding(.trailing, 8)
            }
            
            // 顶栏中间：分段导航控制器 (带动态 Badge 标签)
            ToolbarItem(placement: .principal) {
                Picker("", selection: $appState.selectedTab) {
                    // 1. 调度队列
                    HStack(spacing: 4) {
                        Text("📋 调度队列")
                        let activeCount = queueManager.jobs.filter { $0.status == .pending || $0.status == .waitingForQuota }.count
                        if activeCount > 0 {
                            Text("(\(activeCount))")
                                .font(.caption2.bold())
                        }
                    }
                    .tag(NavigationTab.queue)
                    
                    // 2. 历史留痕
                    HStack(spacing: 4) {
                        Text("🕒 历史留痕")
                        if !historyManager.records.isEmpty {
                            Text("(\(historyManager.records.count))")
                                .font(.caption2.bold())
                        }
                    }
                    .tag(NavigationTab.history)
                    
                    // 3. 额度看板
                    HStack(spacing: 4) {
                        Text("⚡️ 额度看板")
                        Text("(\(Int(quotaEngine.currentQuota.remainingPercent))%)")
                            .font(.caption2.bold())
                    }
                    .tag(NavigationTab.dashboard)
                }
                .pickerStyle(.segmented)
                .frame(minWidth: 360, idealWidth: 420)
            }
            
            // 顶栏右侧：新建任务 Action (⌘N)
            ToolbarItem(placement: .primaryAction) {
                Button {
                    appState.openNewJobSheet()
                } label: {
                    Label("新建任务", systemImage: "plus")
                        .font(.subheadline.bold())
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        .sheet(isPresented: $appState.isShowingJobSheet) {
            JobEditorSheetView(job: appState.editingJob)
        }
    }
}
