import SwiftUI

public struct MainSplitView: View {
    @ObservedObject private var appState = AppState.shared
    
    public init() {}
    
    public var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 180, ideal: 210, max: 260)
        } detail: {
            Group {
                switch appState.selectedTab {
                case .composer:
                    JobComposerView()
                case .queue:
                    QueueListView()
                case .dashboard:
                    QuotaDashboardView()
                }
            }
            .frame(minWidth: 500)
        }
        .frame(minWidth: 720, minHeight: 560)
    }
}

