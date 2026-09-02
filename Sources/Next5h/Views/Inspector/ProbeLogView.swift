import SwiftUI

public struct ProbeLogView: View {
    @ObservedObject private var quotaEngine = QuotaProbeEngine.shared
    @ObservedObject private var loc = LocalizationManager.shared
    
    private var isZh: Bool { loc.currentLanguage == .zh }
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(isZh ? "📡 低频自适应探针日志" : "📡 Adaptive Probe Log")
                    .font(.headline)
                Spacer()
                Text(isZh ? "节能模式运行中" : "Eco Mode Active")
                    .font(.caption2)
                    .foregroundStyle(.green)
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(quotaEngine.probeLogs, id: \.self) { log in
                        Text(log)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(8)
            }
            .frame(height: 110)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .textBackgroundColor)))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
    }
}
