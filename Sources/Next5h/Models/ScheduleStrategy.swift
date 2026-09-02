import Foundation

public enum ScheduleStrategy: Codable, Equatable {
    case autoOnQuotaReset(safetyDelayMinutes: Int)
    case customTime(Date)
    case delayDuration(seconds: TimeInterval)
    case dailyAtTime(hour: Int, minute: Int)
    
    public var displayName: String {
        let isZh = LocalizationManager.shared.currentLanguage == .zh
        switch self {
        case .autoOnQuotaReset(let mins):
            return isZh ? "5H额度解封后自动发送 (+\(mins)分钟缓冲)" : "Auto-send on 5H Reset (+\(mins)m buffer)"
        case .customTime(let date):
            let formatter = DateFormatter()
            formatter.dateFormat = "MM-dd HH:mm"
            return isZh ? "指定时间: \(formatter.string(from: date))" : "Specific time: \(formatter.string(from: date))"
        case .delayDuration(let sec):
            let hours = sec / 3600.0
            return isZh ? "延时 \(String(format: "%.1f", hours)) 小时后" : "Delay \(String(format: "%.1f", hours)) hours"
        case .dailyAtTime(let h, let m):
            return isZh ? String(format: "每天 %02d:%02d 准时触发", h, m) : String(format: "Daily at %02d:%02d", h, m)
        }
    }
}
