import Foundation

public final class SmartScheduler {
    public static let shared = SmartScheduler()
    
    private init() {}
    
    /// 计算指定策略的下一次具体执行时间
    public func calculateNextExecutionDate(for strategy: ScheduleStrategy, currentQuota: QuotaSnapshot) -> Date {
        switch strategy {
        case .autoOnQuotaReset(let safetyDelayMinutes):
            // 默认 resets_at + 1 分钟安全缓冲
            let baseDate = currentQuota.resetsAt ?? Date()
            let executionDate = baseDate.addingTimeInterval(Double(safetyDelayMinutes * 60))
            return max(executionDate, Date().addingTimeInterval(5))
            
        case .customTime(let date):
            return date
            
        case .delayDuration(let seconds):
            return Date().addingTimeInterval(seconds)
            
        case .dailyAtTime(let hour, let minute):
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.hour = hour
            components.minute = minute
            components.second = 0
            
            var target = calendar.date(from: components) ?? Date()
            if target <= Date() {
                // 如果今天该时间已过，排到明天
                target = calendar.date(byAdding: .day, value: 1, to: target) ?? target
            }
            return target
        }
    }
}
