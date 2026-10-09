import SwiftUI

public struct StrategyPickerView: View {
    @Binding public var strategy: ScheduleStrategy
    @ObservedObject private var quotaEngine = QuotaProbeEngine.shared
    @ObservedObject private var loc = LocalizationManager.shared
    
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
            
            Picker("", selection: strategyTypeBinding) {
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
                        
                        DatePicker("", selection: dailyTimeBinding, displayedComponents: .hourAndMinute)
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
                                zh: "延时时长: \(String(format: "%.1f", delayHoursBinding.wrappedValue)) 小时后",
                                en: "Delay: \(String(format: "%.1f", delayHoursBinding.wrappedValue)) hours",
                                ja: "遅延時間: \(String(format: "%.1f", delayHoursBinding.wrappedValue)) 時間後"
                            ))
                            .font(.caption.bold())
                            Spacer()
                        }
                        Slider(value: delayHoursBinding, in: 0.5...12, step: 0.5)
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.05)))
                } else if strategyType == 3 {
                    HStack {
                        Text(L10n.tr(zh: "指定日期时间:", en: "Specific Date & Time:", ja: "指定日時:"))
                            .font(.caption.bold())
                        Spacer()
                        DatePicker("", selection: customDateBinding)
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
    }

    // Derive the visible controls from the bound strategy so template changes
    // and saved values always use the same source of truth.
    private var strategyType: Int {
        switch strategy {
        case .autoOnQuotaReset: return 0
        case .dailyAtTime: return 1
        case .delayDuration: return 2
        case .customTime: return 3
        }
    }

    private var strategyTypeBinding: Binding<Int> {
        Binding(get: { strategyType }, set: { type in
            switch strategy {
            case .dailyAtTime: dailyTime = dailyTimeBinding.wrappedValue
            case .delayDuration(let seconds): delayHours = seconds / 3600
            case .customTime(let date): customDate = date
            case .autoOnQuotaReset: break
            }
            switch type {
            case 0: strategy = .autoOnQuotaReset(safetyDelayMinutes: 1)
            case 1:
                let components = Calendar.current.dateComponents([.hour, .minute], from: dailyTime)
                strategy = .dailyAtTime(hour: components.hour ?? 7, minute: components.minute ?? 0)
            case 2: strategy = .delayDuration(seconds: delayHours * 3600)
            case 3: strategy = .customTime(customDate)
            default: break
            }
        })
    }

    private var dailyTimeBinding: Binding<Date> {
        Binding(get: {
            guard case .dailyAtTime(let hour, let minute) = strategy else { return dailyTime }
            return Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: dailyTime) ?? dailyTime
        }, set: { date in
            dailyTime = date
            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            strategy = .dailyAtTime(hour: components.hour ?? 7, minute: components.minute ?? 0)
        })
    }

    private var delayHoursBinding: Binding<Double> {
        Binding(get: {
            if case .delayDuration(let seconds) = strategy { return seconds / 3600 }
            return delayHours
        }, set: { hours in
            delayHours = hours
            strategy = .delayDuration(seconds: hours * 3600)
        })
    }

    private var customDateBinding: Binding<Date> {
        Binding(get: {
            if case .customTime(let date) = strategy { return date }
            return customDate
        }, set: { date in
            customDate = date
            strategy = .customTime(date)
        })
    }
}
