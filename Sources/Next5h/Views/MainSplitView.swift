import SwiftUI

public struct MainSplitView: View {
    @ObservedObject private var appState = AppState.shared
    @ObservedObject private var queueManager = JobQueueManager.shared
    @ObservedObject private var historyManager = DispatchHistoryManager.shared
    @ObservedObject private var quotaEngine = QuotaProbeEngine.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // 1. 现代化悬浮顶栏 (Floating Pill Header)
            HStack(alignment: .center) {
                // 左侧：避开 macOS 交通灯三色按钮，展示精致 Logo 与品牌名
                HStack(spacing: 8) {
                    Image(systemName: "bolt.badge.clock.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.orange)
                    
                    Text("Next5h")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.primary)
                }
                .padding(.leading, 76)
                
                Spacer()
                
                // 中间：悬浮拟态胶囊分段导航 (1:1 绝对映射，零 Bug)
                FloatingPillTabBar(selectedTab: $appState.selectedTab)
                
                Spacer()
                
                // 右侧：对称占位，保证中间胶囊绝对居中且顶部不拥挤
                Color.clear
                    .frame(width: 140, height: 1)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            // 2. 主体工作区
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
        .frame(minWidth: 740, idealWidth: 880, maxWidth: .infinity, minHeight: 540, idealHeight: 640, maxHeight: .infinity)
        .background(
            // 全局快捷键 ⌘N 监听
            Button("") {
                appState.openNewJobSheet()
            }
            .keyboardShortcut("n", modifiers: .command)
            .opacity(0)
        )
        .sheet(isPresented: $appState.isShowingJobSheet) {
            JobEditorSheetView(job: appState.editingJob)
        }
    }
}

/// 现代化悬浮拟态胶囊 Tab 导航组件
struct FloatingPillTabBar: View {
    @Binding var selectedTab: NavigationTab
    @ObservedObject private var queueManager = JobQueueManager.shared
    @ObservedObject private var historyManager = DispatchHistoryManager.shared
    @ObservedObject private var quotaEngine = QuotaProbeEngine.shared
    @Namespace private var pillNamespace
    
    var body: some View {
        HStack(spacing: 3) {
            // 1. 调度队列
            pillItem(
                tab: .queue,
                icon: "list.bullet.rectangle",
                title: "调度队列",
                badgeText: {
                    let count = queueManager.jobs.count
                    return count > 0 ? "\(count)" : nil
                }(),
                badgeColor: .secondary
            )
            
            // 2. 历史留痕 (移除常驻数字，保持极简)
            pillItem(
                tab: .history,
                icon: "clock.arrow.circlepath",
                title: "历史留痕",
                badgeText: nil,
                badgeColor: .secondary
            )
            
            // 3. 额度看板
            pillItem(
                tab: .dashboard,
                icon: "gauge.with.needle",
                title: "额度看板",
                badgeText: "\(Int(quotaEngine.currentQuota.remainingPercent))%",
                badgeColor: quotaEngine.currentQuota.isLocked ? .red : .green
            )
        }
        .padding(3)
        .background(
            Capsule()
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.85))
                .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
        )
        .overlay(
            Capsule()
                .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private func pillItem(
        tab: NavigationTab,
        icon: String,
        title: String,
        badgeText: String?,
        badgeColor: Color
    ) -> some View {
        let isSelected = selectedTab == tab
        
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                selectedTab = tab
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                
                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                
                if let badge = badgeText {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(badgeColor.opacity(isSelected ? 0.2 : 0.12)))
                        .foregroundStyle(badgeColor)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                ZStack {
                    if isSelected {
                        Capsule()
                            .fill(Color(nsColor: .textBackgroundColor))
                            .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
                            .matchedGeometryEffect(id: "ActiveTabIndicator", in: pillNamespace)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }
}
