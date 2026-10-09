import SwiftUI

public struct ProbeLogView: View {
    @ObservedObject private var quotaEngine = QuotaProbeEngine.shared
    @ObservedObject private var loc = LocalizationManager.shared
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(L10n.tr(zh: "📡 低频自适应探针日志", en: "📡 Adaptive Probe Log", ja: "📡 適応型プローブログ"))
                    .font(.headline)
                Spacer()
                Text(L10n.tr(zh: "节能模式运行中", en: "Eco Mode Active", ja: "省電力モード稼働中"))
                    .font(.caption2)
                    .foregroundStyle(Next5hTheme.mint)
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(quotaEngine.probeLogEntries) { entry in
                        Text(entry.formattedMessage(lang: loc.currentLanguage))
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(8)
            }
            .frame(height: 110)
            .background(RoundedRectangle(cornerRadius: 8).fill(Next5hTheme.subtle))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
        }
        .next5hSurface()
    }
}
