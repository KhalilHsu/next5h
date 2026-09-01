import SwiftUI
import AppKit

public struct MainSplitView: View {
    @ObservedObject private var appState = AppState.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // 顶部 Header 区域（高度加倍至 60pt，视觉空间宽裕，Tab 切换组件同步放大）
            TopHeaderView()
            
            Divider()
            
            // 主体工作区
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
        .frame(minWidth: 740, idealWidth: 880, maxWidth: .infinity, minHeight: 560, idealHeight: 680, maxHeight: .infinity)
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

/// 顶部 Header 栏：高度翻倍（60pt），对齐 macOS 窗口规范并居中承载放大后的 Tab 导航
public struct TopHeaderView: View {
    @ObservedObject private var appState = AppState.shared
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // 左侧：交通灯安全边距与应用品牌
            HStack(spacing: 0) {
                Spacer()
                    .frame(width: 78)
                
                HStack(spacing: 7) {
                    Image(systemName: "timer")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                    
                    Text("Next5h")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.primary)
                }
                
                Spacer()
            }
            
            // 中央：居中放大的 Tab 切换器
            NavigationToolbarView()
        }
        .frame(height: 60)
        .frame(maxWidth: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

/// 居中放大的导航 Tab 切换器：对齐 macOS 官方全圆角选中态与更舒适的点击区域
public struct NavigationToolbarView: View {
    @ObservedObject private var appState = AppState.shared
    @ObservedObject private var queueManager = JobQueueManager.shared
    @ObservedObject private var quotaEngine = QuotaProbeEngine.shared
    @Namespace private var segmentNamespace
    @State private var hoveredTab: NavigationTab? = nil

    public init() {}

    private var quotaBadgeColor: Color {
        let quota = quotaEngine.currentQuota
        if quota.isLocked || quota.remainingPercent < 20 {
            return .red
        } else if quota.remainingPercent < 50 {
            return .orange
        } else {
            return .green
        }
    }

    public var body: some View {
        let activeCount = queueManager.jobs.filter { $0.status == .pending || $0.status == .waitingForQuota }.count
        let remainingPercent = Int(quotaEngine.currentQuota.remainingPercent)

        HStack(spacing: 0) {
            tabButton(
                title: "调度队列",
                badge: activeCount > 0 ? "\(activeCount)" : nil,
                badgeColor: .blue,
                tab: .queue
            )

            divider(between: .queue, and: .history)

            tabButton(
                title: "历史留痕",
                badge: nil,
                badgeColor: .secondary,
                tab: .history
            )

            divider(between: .history, and: .dashboard)

            tabButton(
                title: "额度看板",
                badge: "\(remainingPercent)%",
                badgeColor: quotaBadgeColor,
                tab: .dashboard
            )
        }
        .padding(3.5)
        .background(
            Capsule()
                .fill(Color(nsColor: .quaternaryLabelColor).opacity(0.35))
                .overlay(
                    Capsule()
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.8)
                )
        )
        .fixedSize()
    }

    @ViewBuilder
    private func divider(between tab1: NavigationTab, and tab2: NavigationTab) -> some View {
        if appState.selectedTab != tab1 && appState.selectedTab != tab2 {
            Rectangle()
                .fill(Color(nsColor: .separatorColor).opacity(0.55))
                .frame(width: 1, height: 16)
        } else {
            Spacer().frame(width: 1)
        }
    }

    private func tabButton(title: String, badge: String?, badgeColor: Color, tab: NavigationTab) -> some View {
        let isSelected = appState.selectedTab == tab
        let isHovered = hoveredTab == tab && !isSelected

        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                appState.selectedTab = tab
            }
        } label: {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 13.5, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? Color.primary : Color(nsColor: .secondaryLabelColor))

                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .padding(.horizontal, 6.5)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(badgeColor.opacity(isSelected ? 0.18 : 0.12))
                        )
                        .foregroundStyle(badgeColor)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6.5)
            .background {
                if isSelected {
                    Capsule()
                        .fill(Color(nsColor: .textBackgroundColor))
                        .shadow(color: Color.black.opacity(0.12), radius: 2, x: 0, y: 1)
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.black.opacity(0.05), lineWidth: 0.5)
                        )
                        .matchedGeometryEffect(id: "selected_nav_tab", in: segmentNamespace)
                } else if isHovered {
                    Capsule()
                        .fill(Color.primary.opacity(0.05))
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { h in
            hoveredTab = h ? tab : nil
        }
    }
}


