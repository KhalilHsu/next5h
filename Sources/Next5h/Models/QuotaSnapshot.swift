import Foundation

public struct QuotaSnapshot: Codable, Equatable {
    public var usedPercent: Double
    public var resetsAt: Date?
    public var windowMinutes: Int
    public var weeklyUsedPercent: Double?
    public var weeklyResetsAt: Date?
    public var capturedAt: Date
    public var isConnectedToChatGPTApp: Bool
    public var chatGPTPid: Int32?
    public var statusDescription: String
    
    public init(
        usedPercent: Double = 0,
        resetsAt: Date? = nil,
        windowMinutes: Int = 300,
        weeklyUsedPercent: Double? = nil,
        weeklyResetsAt: Date? = nil,
        capturedAt: Date = Date(),
        isConnectedToChatGPTApp: Bool = false,
        chatGPTPid: Int32? = nil,
        statusDescription: String = "就绪"
    ) {
        self.usedPercent = usedPercent
        self.resetsAt = resetsAt
        self.windowMinutes = windowMinutes
        self.weeklyUsedPercent = weeklyUsedPercent
        self.weeklyResetsAt = weeklyResetsAt
        self.capturedAt = capturedAt
        self.isConnectedToChatGPTApp = isConnectedToChatGPTApp
        self.chatGPTPid = chatGPTPid
        self.statusDescription = statusDescription
    }
    
    /// 5H 剩余可用百分比（对齐官方“剩余”逻辑）
    public var remainingPercent: Double {
        return max(0.0, 100.0 - usedPercent)
    }
    
    /// 周额度剩余可用百分比（对齐官方“剩余”逻辑）
    public var weeklyRemainingPercent: Double? {
        guard let wUsed = weeklyUsedPercent else { return nil }
        return max(0.0, 100.0 - wUsed)
    }
    
    public var isLocked: Bool {
        guard let resetsAt = resetsAt else { return false }
        return resetsAt > Date() && usedPercent >= 99.0
    }
    
    public var remainingSeconds: TimeInterval {
        guard let resetsAt = resetsAt else { return 0 }
        return max(0, resetsAt.timeIntervalSince(Date()))
    }
    
    public var formattedRemainingTime: String {
        let isZh = LocalizationManager.shared.currentLanguage == .zh
        let sec = Int(remainingSeconds)
        if sec <= 0 { return isZh ? "额度充裕 / 未受限" : "Unrestricted" }
        let hours = sec / 3600
        let mins = (sec % 3600) / 60
        let secs = sec % 60
        if hours > 0 {
            return isZh ? String(format: "%d小时 %02d分 %02d秒", hours, mins, secs)
                        : String(format: "%dh %02dm %02ds", hours, mins, secs)
        } else {
            return isZh ? String(format: "%d分 %02d秒", mins, secs)
                        : String(format: "%dm %02ds", mins, secs)
        }
    }
    
    public var weeklyRemainingSeconds: TimeInterval {
        guard let weeklyResetsAt = weeklyResetsAt else { return 0 }
        return max(0, weeklyResetsAt.timeIntervalSince(Date()))
    }
    
    public var formattedWeeklyRemainingTime: String {
        let isZh = LocalizationManager.shared.currentLanguage == .zh
        let sec = Int(weeklyRemainingSeconds)
        if sec <= 0 { return isZh ? "未受限" : "Unrestricted" }
        let days = sec / 86400
        let hours = (sec % 86400) / 3600
        let mins = (sec % 3600) / 60
        if days > 0 {
            return isZh ? "\(days)天 \(hours)小时" : "\(days)d \(hours)h"
        } else if hours > 0 {
            return isZh ? "\(hours)小时 \(mins)分" : "\(hours)h \(mins)m"
        } else {
            return isZh ? "\(mins)分钟" : "\(mins)m"
        }
    }
}
