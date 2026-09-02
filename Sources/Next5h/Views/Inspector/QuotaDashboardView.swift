import SwiftUI

public struct QuotaDashboardView: View {
    @ObservedObject private var quotaEngine = QuotaProbeEngine.shared
    @ObservedObject private var loc = LocalizationManager.shared
    
    public init() {}
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // 顶部标题与刷新
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 7) {
                            Image(systemName: "gauge.with.needle")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.secondary)
                            Text(L10n.dashboardTitle)
                                .font(.title3.bold())
                        }
                        Text(L10n.dashboardSubtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                    
                    Button(action: { quotaEngine.refreshNow() }) {
                        Label(quotaEngine.isProbing ? L10n.dashboardSyncing : L10n.dashboardRefresh, systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .disabled(quotaEngine.isProbing)
                }
                .padding(.top, 14)
                .padding(.bottom, 2)
                
                // 本地 ChatGPT 客户端连接状态
                HStack(spacing: 8) {
                    Circle()
                        .fill(quotaEngine.currentQuota.isConnectedToChatGPTApp ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    if quotaEngine.currentQuota.isConnectedToChatGPTApp {
                        Text(L10n.dashboardConnectedChatGPT(pid: quotaEngine.currentQuota.chatGPTPid ?? 0))
                            .font(.caption.bold())
                            .foregroundStyle(.green)
                    } else {
                        Text(L10n.dashboardChatGPTNotRunning)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .controlBackgroundColor).opacity(0.6)))
                
                // 100% 对齐官方“剩余”逻辑的双卡片 (垂直排列以适应 Setting 紧凑宽度)
                VStack(spacing: 12) {
                    // 1. 5 小时滑动窗口主卡片
                    let remaining5h = quotaEngine.currentQuota.remainingPercent
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L10n.dashboard5hCardTitle)
                                    .font(.headline)
                                Text(L10n.dashboard5hUsage(remaining: remaining5h, used: quotaEngine.currentQuota.usedPercent))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(L10n.dashboardRemaining(percent: remaining5h))
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(quotaEngine.currentQuota.isLocked ? .red : .primary)
                        }
                        
                        ProgressView(value: min(100.0, remaining5h), total: 100.0)
                            .progressViewStyle(.linear)
                            .tint(quotaEngine.currentQuota.isLocked ? .red : (remaining5h < 20 ? .orange : .green))
                            .scaleEffect(x: 1, y: 1.5, anchor: .center)
                        
                        Divider()
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L10n.dashboardResetsAt)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                if let resetsAt = quotaEngine.currentQuota.resetsAt {
                                    Text(formatDateTime(resetsAt))
                                        .font(.caption.bold())
                                } else {
                                    Text(L10n.menuUnrestricted)
                                        .font(.caption)
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(L10n.dashboardCountdown)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(quotaEngine.currentQuota.formattedRemainingTime)
                                    .font(.caption.bold())
                                    .foregroundStyle(quotaEngine.currentQuota.isLocked ? .red : .green)
                            }
                        }
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor).opacity(0.55)))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 0.8))
                    
                    // 2. 7 天每周额度窗口卡片
                    let weeklyRem = quotaEngine.currentQuota.weeklyRemainingPercent ?? 100.0
                    let weeklyUsed = quotaEngine.currentQuota.weeklyUsedPercent ?? 0.0
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L10n.dashboardWeeklyCardTitle)
                                    .font(.headline)
                                Text(L10n.dashboardWeeklyUsage(remaining: weeklyRem, used: weeklyUsed))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(L10n.dashboardRemaining(percent: weeklyRem))
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(.blue)
                        }
                        
                        ProgressView(value: min(100.0, weeklyRem), total: 100.0)
                            .progressViewStyle(.linear)
                            .tint(.blue)
                            .scaleEffect(x: 1, y: 1.5, anchor: .center)
                        
                        Divider()
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L10n.dashboardWeeklyReset)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                if let wReset = quotaEngine.currentQuota.weeklyResetsAt {
                                    Text(formatDateTime(wReset))
                                        .font(.caption.bold())
                                } else {
                                    Text(L10n.tr(zh: "每周循环", en: "Weekly Cycle", ja: "週間サイクル"))
                                        .font(.caption)
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(L10n.dashboardWeeklyResetRemaining)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(quotaEngine.currentQuota.formattedWeeklyRemainingTime)
                                    .font(.caption.bold())
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor).opacity(0.55)))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 0.8))
                }
                
                // 探针运行日志
                ProbeLogView()
                
                // 系统权限与健康状态
                PermissionsCardView()
                    .padding(.bottom, 20)
            }
            .padding(.horizontal, 24)
        }
        .scrollContentBackground(.hidden)
    }
}
