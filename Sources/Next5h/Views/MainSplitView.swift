import SwiftUI
import AppKit

public struct MainSplitView: View {
    @ObservedObject private var appState = AppState.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // 顶部 Header 区域（左侧品牌 + 严格居中的放大的 Tab 切换器）
            TopHeaderView()
            
            // 增加 Tab 到下方面板的舒缓呼吸间距
            Spacer().frame(height: 6)
            
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
        .frame(minWidth: 720, idealWidth: 720, maxWidth: .infinity, minHeight: 520, idealHeight: 640, maxHeight: .infinity)
        .background(
            VisualEffectView(material: .sidebar, blendingMode: .behindWindow, state: .active)
                .ignoresSafeArea()
        )
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

/// macOS 原生液态毛玻璃视觉效果视图 (NSVisualEffectView 封装)
public struct VisualEffectView: NSViewRepresentable {
    public var material: NSVisualEffectView.Material
    public var blendingMode: NSVisualEffectView.BlendingMode
    public var state: NSVisualEffectView.State

    public init(
        material: NSVisualEffectView.Material = .sidebar,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        state: NSVisualEffectView.State = .active
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.state = state
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}

/// 顶部 Header 栏：最左侧紧邻交通灯放置应用 Logo & 品牌名，中央严格居中承载放大的 Tab 导航
public struct TopHeaderView: View {
    @ObservedObject private var appState = AppState.shared
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // 左侧：与下方面板所有内容、卡片完全左对齐（x = 24）
            HStack(spacing: 0) {
                HStack(spacing: 6) {
                    Image(systemName: "timer")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                    
                    Text("Next5h")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.primary)
                }
                .padding(.leading, 24)
                
                Spacer()
            }
            
            // 中央：严格居中的 3 个 Tab（位置与样式保持 100% 不变）
            NavigationToolbarView()
        }
        .frame(height: 56)
        .frame(maxWidth: .infinity)
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
            HStack(spacing: 5) {
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? Color.primary : Color(nsColor: .secondaryLabelColor))

                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1.5)
                        .background(
                            Capsule()
                                .fill(badgeColor.opacity(isSelected ? 0.18 : 0.12))
                        )
                        .foregroundStyle(badgeColor)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
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


