import SwiftUI

public struct DispatchModePickerView: View {
    @Binding public var dispatchMode: DispatchMode
    @ObservedObject private var loc = LocalizationManager.shared
    
    private var isZh: Bool { loc.currentLanguage == .zh }
    
    public init(dispatchMode: Binding<DispatchMode>) {
        self._dispatchMode = dispatchMode
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(isZh ? "发送模式" : "Dispatch Mode", systemImage: "paperplane")
                .font(.subheadline.bold())
            
            Picker("", selection: $dispatchMode) {
                ForEach(DispatchMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            
            Text(dispatchMode.detailDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(nsColor: .controlBackgroundColor).opacity(0.6)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.15), lineWidth: 1))
    }
}
