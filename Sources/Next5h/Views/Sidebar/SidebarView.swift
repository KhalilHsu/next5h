import SwiftUI

public struct SidebarView: View {
    @ObservedObject private var appState = AppState.shared
    @ObservedObject private var queueManager = JobQueueManager.shared
    @ObservedObject private var quotaEngine = QuotaProbeEngine.shared
    
    @State private var isHoveringDashboardCard = false
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // App 标题
            HStack(spacing: 8) {
                Image(systemName: "bolt.badge.clock.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("Next5h")
                        .font(.headline.bold())
                    Text("Codex 5H 自动续航")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            
            Divider()
            
            // 导航项 (只保留 任务编排 和 调度队列)
            List(selection: $appState.selectedTab) {
                Section("工作区") {
                    ForEach(NavigationTab.sidebarWorkspaceTabs) { tab in
                        HStack {
                            Label(tab.title, systemImage: tab.iconName)
                            Spacer()
                            if tab == .queue && !queueManager.jobs.isEmpty {
                                Text("\(queueManager.jobs.count)")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.orange.opacity(0.2)))
                                    .foregroundStyle(.orange)
                            }
                        }
                        .tag(tab)
                    }
                }
            }
            .listStyle(.sidebar)
            
            Spacer()
            
            Divider()
            
            // 左下角可点击进入仪表盘的实时额度卡片
            Button {
                appState.selectedTab = .dashboard
            } label: {
                VStack(alignment: .leading, spacing: 10) {
                    // 1. 5H 额度剩余
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Circle()
                                .fill(quotaEngine.currentQuota.isLocked ? Color.red : Color.green)
                                .frame(width: 7, height: 7)
                            Text(quotaEngine.currentQuota.isLocked ? "5H 限流锁定" : "5H 剩余")
                                .font(.caption.bold())
                            Spacer()
                            Text("\(Int(quotaEngine.currentQuota.remainingPercent))%")
                                .font(.caption2.bold())
                                .foregroundStyle(quotaEngine.currentQuota.isLocked ? .red : .primary)
                        }
                        
                        ProgressView(value: min(100.0, quotaEngine.currentQuota.remainingPercent), total: 100.0)
                            .progressViewStyle(.linear)
                            .tint(quotaEngine.currentQuota.isLocked ? .red : (quotaEngine.currentQuota.remainingPercent < 20 ? .orange : .green))
                    }
                    
                    // 2. 周额度剩余
                    if let weeklyRemaining = quotaEngine.currentQuota.weeklyRemainingPercent {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 7, height: 7)
                                Text("周额度剩余")
                                    .font(.caption.bold())
                                Spacer()
                                Text("\(Int(weeklyRemaining))%")
                                    .font(.caption2.bold())
                            }
                            
                            ProgressView(value: min(100.0, weeklyRemaining), total: 100.0)
                                .progressViewStyle(.linear)
                                .tint(.blue)
                        }
                    }
                    
                    // 底部跳转指引
                    HStack {
                        Text("点击查看额度仪表盘")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 2)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(appState.selectedTab == .dashboard ? Color.accentColor.opacity(0.12) : (isHoveringDashboardCard ? Color.secondary.opacity(0.08) : Color.clear))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(appState.selectedTab == .dashboard ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .padding(8)
            .onHover { isHoveringDashboardCard = $0 }
        }
    }
}
