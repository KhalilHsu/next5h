import Foundation

public enum ScheduleStrategy: Codable, Equatable {
    case autoOnQuotaReset(safetyDelayMinutes: Int)
    case customTime(Date)
    case delayDuration(seconds: TimeInterval)
    case dailyAtTime(hour: Int, minute: Int)
    
    public var displayName: String {
        switch self {
        case .autoOnQuotaReset(let mins):
            return L10n.tr(
                zh: "5H额度解封后自动发送 (+\(mins)分钟缓冲)",
                en: "Auto-send on 5H Reset (+\(mins)m buffer)",
                ja: "5H枠復活時に自動送信 (+\(mins)分バッファ)"
            )
        case .customTime(let date):
            let formatter = DateFormatter()
            formatter.dateFormat = "MM-dd HH:mm"
            return L10n.tr(
                zh: "指定时间: \(formatter.string(from: date))",
                en: "Specific time: \(formatter.string(from: date))",
                ja: "指定日時: \(formatter.string(from: date))"
            )
        case .delayDuration(let sec):
            let hours = sec / 3600.0
            return L10n.tr(
                zh: "延时 \(String(format: "%.1f", hours)) 小时后",
                en: "Delay \(String(format: "%.1f", hours)) hours",
                ja: "\(String(format: "%.1f", hours)) 時間遅延"
            )
        case .dailyAtTime(let h, let m):
            return L10n.tr(
                zh: String(format: "每天 %02d:%02d 准时触发", h, m),
                en: String(format: "Daily at %02d:%02d", h, m),
                ja: String(format: "毎日 %02d:%02d に送信", h, m)
            )
        }
    }
}
