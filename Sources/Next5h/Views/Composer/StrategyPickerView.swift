import SwiftUI

public struct StrategyPickerView: View {
    @Binding public var strategy: ScheduleStrategy
    @ObservedObject private var quotaEngine = QuotaProbeEngine.shared
    
    @State private var strategyType: Int = 1 // 0: 5H Reset, 1: Daily Repeat, 2: Delay, 3: Custom Date
    @State private var dailyTime: Date = {
        var comp = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comp.hour = 7
        comp.minute = 0
        return Calendar.current.date(from: comp) ?? Date()
    }()
    @State private var delayHours: Double = 3.5
    @State private var customDate: Date = Date().addingTimeInterval(3600 * 3)
    
    public init(strategy: Binding<ScheduleStrategy>) {
        self._strategy = strategy
    }
    
    private func formattedTargetResetTime(_ reset: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: reset.addingTimeInterval(60))
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("⏰ 触发策略 (Trigger Strategy)")
                .font(.headline)
            
            Picker("", selection: $strategyType) {
                Text("🌅 每日定时重复").tag(1)
                Text("⚡️ 5H解封自动 (+1m)").tag(0)
                Text("⏳ 延时 X 小时").tag(2)
                Text("📅 具体日期时间").tag(3)
            }
            .pickerStyle(.segmented)
            
            Group {
                if strategyType == 1 {
                    HStack(spacing: 12) {
                        Image(systemName: "repeat.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.orange)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("每日循环触发时间：")
                                .font(.caption.bold())
                            Text("每天在该时间自动唤醒 Mac 并发送任务")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        DatePicker("", selection: $dailyTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.08)))
                } else if strategyType == 0 {
                    HStack {
                        Image(systemName: "hourglass.badge.plus")
                            .foregroundStyle(.orange)
                        if let reset = quotaEngine.currentQuota.resetsAt {
                            Text("预计在 \(formattedTargetResetTime(reset)) 触发 (+1分钟安全缓冲)")
                                .font(.caption)
                        } else {
                            Text("当前未限流，将在 5H 额度重置时自动触发 (或在检测到限流后准时解锁)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else if strategyType == 2 {
                    HStack {
                        Text("延时: \(String(format: "%.1f", delayHours)) 小时后")
                            .font(.subheadline)
                        Slider(value: $delayHours, in: 0.5...12, step: 0.5)
                    }
                } else if strategyType == 3 {
                    DatePicker("选择具体执行时间", selection: $customDate)
                        .datePickerStyle(.field)
                }
            }
            .padding(.top, 2)
            
            Divider()
                .padding(.vertical, 2)
            
            // 锁屏与休眠唤醒保障提示
            PowerQuickTipBanner()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(nsColor: .controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
        .onChange(of: strategyType) { _, _ in syncStrategy() }
        .onChange(of: dailyTime) { _, _ in syncStrategy() }
        .onChange(of: delayHours) { _, _ in syncStrategy() }
        .onChange(of: customDate) { _, _ in syncStrategy() }
        .onAppear {
            initFromStrategy()
        }
    }
    
    private func initFromStrategy() {
        switch strategy {
        case .dailyAtTime(let h, let m):
            strategyType = 1
            var comp = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            comp.hour = h
            comp.minute = m
            dailyTime = Calendar.current.date(from: comp) ?? Date()
        case .autoOnQuotaReset:
            strategyType = 0
        case .delayDuration(let sec):
            strategyType = 2
            delayHours = sec / 3600.0
        case .customTime(let date):
            strategyType = 3
            customDate = date
        }
    }
    
    private func syncStrategy() {
        switch strategyType {
        case 1:
            let comp = Calendar.current.dateComponents([.hour, .minute], from: dailyTime)
            strategy = .dailyAtTime(hour: comp.hour ?? 7, minute: comp.minute ?? 0)
        case 0:
            strategy = .autoOnQuotaReset(safetyDelayMinutes: 1)
        case 2:
            strategy = .delayDuration(seconds: delayHours * 3600.0)
        case 3:
            strategy = .customTime(customDate)
        default:
            break
        }
    }
}
