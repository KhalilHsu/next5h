import SwiftUI

public struct StrategyPickerView: View {
    @Binding public var strategy: ScheduleStrategy
    @ObservedObject private var quotaEngine = QuotaProbeEngine.shared
    @ObservedObject private var loc = LocalizationManager.shared
    
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
            Label(L10n.tr(zh: "触发策略", en: "Trigger Schedule", ja: "トリガー条件"), systemImage: "clock.badge.checkmark")
                .font(.subheadline.bold())
            
            Picker("", selection: $strategyType) {
                Text(L10n.tr(zh: "🌅 每日定时", en: "🌅 Daily", ja: "🌅 毎日定時")).tag(1)
                Text(L10n.tr(zh: "⚡️ 5H解封 (+1m)", en: "⚡️ 5H Reset (+1m)", ja: "⚡️ 5H復活時 (+1分)")).tag(0)
                Text(L10n.tr(zh: "⏳ 延时 X 小时", en: "⏳ Delay X Hours", ja: "⏳ X時間遅延")).tag(2)
                Text(L10n.tr(zh: "📅 具体时间", en: "📅 Specific Date", ja: "📅 日時指定")).tag(3)
            }
            .pickerStyle(.segmented)
            
            Group {
                if strategyType == 1 {
                    HStack(spacing: 12) {
                        Image(systemName: "repeat.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.orange)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.tr(zh: "每日循环触发时间：", en: "Daily Trigger Time:", ja: "毎日の送信時刻："))
                                .font(.caption.bold())
                            Text(L10n.tr(
                                zh: "每天在该时间自动唤醒 Mac 并发送任务",
                                en: "Wakes Mac daily at this time to send message",
                                ja: "毎日この時刻にMacを自動起動してメッセージを送信します"
                            ))
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
                    HStack(spacing: 8) {
                        Image(systemName: "hourglass.badge.plus")
                            .foregroundStyle(.orange)
                        if let reset = quotaEngine.currentQuota.resetsAt {
                            Text(L10n.tr(
                                zh: "预计在 \(formattedTargetResetTime(reset)) 自动派发 (+1分钟安全缓冲)",
                                en: "Scheduled at \(formattedTargetResetTime(reset)) (+1m safety buffer)",
                                ja: "\(formattedTargetResetTime(reset)) に自動送信予定 (+1分バッファ)"
                            ))
                            .font(.caption)
                        } else {
                            Text(L10n.tr(
                                zh: "当前未限流，将在 5H 额度重置时自动触发 (或在检测到限流后准时解锁)",
                                en: "Currently not rate-limited. Will auto-trigger on 5H quota reset",
                                ja: "現在制限なし。5Hクォータ復活時に自動送信されます"
                            ))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.05)))
                } else if strategyType == 2 {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(L10n.tr(
                                zh: "延时时长: \(String(format: "%.1f", delayHours)) 小时后",
                                en: "Delay: \(String(format: "%.1f", delayHours)) hours",
                                ja: "遅延時間: \(String(format: "%.1f", delayHours)) 時間後"
                            ))
                            .font(.caption.bold())
                            Spacer()
                        }
                        Slider(value: $delayHours, in: 0.5...12, step: 0.5)
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.05)))
                } else if strategyType == 3 {
                    HStack {
                        Text(L10n.tr(zh: "指定日期时间:", en: "Specific Date & Time:", ja: "指定日時:"))
                            .font(.caption.bold())
                        Spacer()
                        DatePicker("", selection: $customDate)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.05)))
                }
            }
            
            Divider()
            
            // 锁屏与休眠唤醒保障提示
            PowerQuickTipBanner()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(nsColor: .controlBackgroundColor).opacity(0.6)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.15), lineWidth: 1))
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
