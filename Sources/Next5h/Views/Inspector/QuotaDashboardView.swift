import SwiftUI

public struct QuotaDashboardView: View {
    @ObservedObject private var quotaEngine = QuotaProbeEngine.shared
    @ObservedObject private var loc = LocalizationManager.shared

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.tr(zh: "额度看板", en: "Quota Dashboard", ja: "クォータダッシュボード"))
                            .font(.system(size: 21, weight: .semibold))
                        Text(L10n.dashboardSubtitle)
                            .font(.caption)
                            .foregroundStyle(Next5hTheme.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    Button(action: { quotaEngine.refreshNow() }) {
                        Next5hButtonLabel(quotaEngine.isProbing ? L10n.dashboardSyncing : L10n.dashboardRefresh, systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(Next5hButtonStyle(kind: .secondary))
                    .disabled(quotaEngine.isProbing)
                }
                .padding(.top, 24)
                .padding(.bottom, 6)

                HStack(spacing: 8) {
                    Circle()
                        .fill(quotaEngine.currentQuota.isConnectedToChatGPTApp ? Next5hTheme.mint : Next5hTheme.secondary)
                        .frame(width: 7, height: 7)
                    Text(quotaEngine.currentQuota.isConnectedToChatGPTApp
                         ? L10n.dashboardConnectedChatGPT(pid: quotaEngine.currentQuota.chatGPTPid ?? 0)
                         : L10n.dashboardChatGPTNotRunning)
                        .font(.caption)
                        .foregroundStyle(Next5hTheme.secondary)
                    Spacer()
                    if CodexSessionWatcher.shared.isInActiveBurstWindow {
                        Text(L10n.tr(zh: "活跃追踪 · 每分钟更新", en: "Active tracking · Every minute", ja: "高頻度追跡 · 毎分更新"))
                            .font(.caption2)
                            .foregroundStyle(Next5hTheme.accent)
                    }
                }

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 16) {
                        fiveHourCard.frame(minWidth: 300)
                        weeklyCard.frame(minWidth: 300)
                    }
                    VStack(spacing: 16) {
                        fiveHourCard
                        weeklyCard
                    }
                }
                // Keep logs and all permission actions directly available.
                ProbeLogView()
                PermissionsCardView()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .scrollContentBackground(.hidden)
    }

    private var fiveHourCard: some View {
        let quota = quotaEngine.currentQuota
        let remaining = quota.remainingPercent
        let color: Color = quota.isLocked ? .red : (remaining < 20 ? Next5hTheme.warning : Next5hTheme.mint)
        return QuotaSummaryCard(
            title: L10n.tr(zh: "5 小时额度", en: "5-hour Quota", ja: "5時間クォータ"),
            remaining: remaining,
            used: quota.usedPercent,
            color: color,
            resetTitle: quota.isLocked ? L10n.dashboardResetsAt : L10n.tr(zh: "重置时间", en: "Reset time", ja: "リセット時刻"),
            resetDate: quota.resetsAt,
            noResetText: L10n.menuUnrestricted,
            countdownTitle: quota.isLocked ? L10n.dashboardCountdown : L10n.tr(zh: "距重置", en: "Until reset", ja: "リセットまで"),
            countdown: quota.formattedRemainingTime
        )
    }

    private var weeklyCard: some View {
        let quota = quotaEngine.currentQuota
        return QuotaSummaryCard(
            title: L10n.tr(zh: "每周额度", en: "Weekly Quota", ja: "週間クォータ"),
            remaining: quota.weeklyRemainingPercent ?? 100,
            used: quota.weeklyUsedPercent ?? 0,
            color: Next5hTheme.accent,
            resetTitle: L10n.dashboardWeeklyReset,
            resetDate: quota.weeklyResetsAt,
            noResetText: L10n.tr(zh: "每周循环", en: "Weekly Cycle", ja: "週間サイクル"),
            countdownTitle: L10n.dashboardWeeklyResetRemaining,
            countdown: quota.formattedWeeklyRemainingTime
        )
    }
}

private struct QuotaSummaryCard: View {
    let title: String
    let remaining: Double
    let used: Double
    let color: Color
    let resetTitle: String
    let resetDate: Date?
    let noResetText: String
    let countdownTitle: String
    let countdown: String

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = Calendar.current.isDateInToday(date) ? "HH:mm" : "MM-dd HH:mm"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title).font(.system(size: 14, weight: .semibold))
                Spacer()
                Text(L10n.tr(zh: "已用 \(String(format: "%.0f", used))%", en: "\(String(format: "%.0f", used))% used", ja: "\(String(format: "%.0f", used))% 使用済み"))
                    .font(.caption2)
                    .foregroundStyle(Next5hTheme.secondary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(String(format: "%.0f", remaining))
                    .font(.system(size: 36, weight: .medium, design: .rounded))
                    .foregroundStyle(color)
                    .monospacedDigit()
                Text(L10n.tr(zh: "% 剩余", en: "% remaining", ja: "% 残り"))
                    .font(.caption)
                    .foregroundStyle(Next5hTheme.secondary)
            }
            .help(L10n.dashboardRemaining(percent: remaining))
            ProgressView(value: min(100, remaining), total: 100)
                .progressViewStyle(QuotaProgressStyle(color: color))
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(resetTitle)
                    Spacer(minLength: 6)
                    Text(resetDate.map(formattedDate) ?? noResetText)
                        .foregroundStyle(Next5hTheme.ink)
                        .monospacedDigit()
                }
                HStack(alignment: .firstTextBaseline) {
                    Text(countdownTitle)
                    Spacer(minLength: 6)
                    Text(countdown).monospacedDigit().foregroundStyle(color)
                }
            }
            .font(.caption2)
            .foregroundStyle(Next5hTheme.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .next5hSurface(padding: 18)
    }
}

private struct QuotaProgressStyle: ProgressViewStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Next5hTheme.border.opacity(0.55))
                Capsule().fill(color)
                    .frame(width: geometry.size.width * max(0, min(1, configuration.fractionCompleted ?? 0)))
            }
        }
        .frame(height: 5)
    }
}
