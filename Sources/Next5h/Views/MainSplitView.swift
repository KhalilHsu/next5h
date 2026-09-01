import SwiftUI
import AppKit

public struct MainSplitView: View {
    @ObservedObject private var appState = AppState.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // 主体工作区；品牌与导航位于原生 macOS Toolbar
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

/// 原生 Toolbar 中央导航：对齐 macOS 官方全圆角选中态与突出视觉规范
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
        .padding(.leading, 2.5)
        .padding(.trailing, 2.5)
        .padding(.top, 4.0)
        .padding(.bottom, 1.0)
        .fixedSize()
    }

    @ViewBuilder
    private func divider(between tab1: NavigationTab, and tab2: NavigationTab) -> some View {
        if appState.selectedTab != tab1 && appState.selectedTab != tab2 {
            Rectangle()
                .fill(Color(nsColor: .separatorColor).opacity(0.55))
                .frame(width: 1, height: 11)
        } else {
            Spacer().frame(width: 1)
        }
    }

    private func tabButton(title: String, badge: String?, badgeColor: Color, tab: NavigationTab) -> some View {
        let isSelected = appState.selectedTab == tab
        let isHovered = hoveredTab == tab && !isSelected

        return Button {
            withAnimation(.easeInOut(duration: 0.16)) {
                appState.selectedTab = tab
            }
        } label: {
            HStack(spacing: 5) {
                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.primary : Color(nsColor: .secondaryLabelColor))

                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .padding(.horizontal, 5.5)
                        .padding(.vertical, 1.5)
                        .background(
                            Capsule()
                                .fill(badgeColor.opacity(isSelected ? 0.18 : 0.12))
                        )
                        .foregroundStyle(badgeColor)
                }
            }
            .padding(.horizontal, 9.5)
            .padding(.vertical, 3.5)
            .background {
                if isSelected {
                    Capsule()
                        .fill(Color(nsColor: .textBackgroundColor))
                        .shadow(color: Color.black.opacity(0.12), radius: 1.5, x: 0, y: 0.5)
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.black.opacity(0.04), lineWidth: 0.5)
                        )
                        .matchedGeometryEffect(id: "selected_nav_tab", in: segmentNamespace)
                } else if isHovered {
                    Capsule()
                        .fill(Color.primary.opacity(0.04))
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { h in
            hoveredTab = h ? tab : nil
        }
    }
}


