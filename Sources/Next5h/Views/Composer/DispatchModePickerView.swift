import SwiftUI

public struct DispatchModePickerView: View {
    @Binding public var dispatchMode: DispatchMode
    @ObservedObject private var loc = LocalizationManager.shared
    
    public init(dispatchMode: Binding<DispatchMode>) {
        self._dispatchMode = dispatchMode
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Next5hSectionHeading(title: L10n.tr(zh: "发送方式", en: "Delivery", ja: "送信方法"), symbol: "paperplane")
            Next5hSegmentedControl(
                label: L10n.tr(zh: "发送方式", en: "Delivery", ja: "送信方法"),
                selection: $dispatchMode,
                options: DispatchMode.allCases.map { mode in
                    .init(value: mode, title: mode == .silentAPI
                          ? L10n.tr(zh: "后台发送", en: "Background", ja: "バックグラウンド")
                          : L10n.tr(zh: "前台窗口", en: "Foreground", ja: "前面ウィンドウ"))
                }
            )

            Text(dispatchMode.detailDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
        }

    }
}
