import SwiftUI

public struct QuotaDashboardView: View {
    @ObservedObject private var quotaEngine = QuotaProbeEngine.shared
    
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
                            Text("5H 与周额度监控看板")
                                .font(.title3.bold())
                        }
                        Text("直连 OpenAI 官方接口实时探活与滑动窗口用量监测")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                    
                    Button(action: { quotaEngine.refreshNow() }) {
                        Label(quotaEngine.isProbing ? "同步中..." : "立即刷新", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .disabled(quotaEngine.isProbing)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 4)
                
                // 本地 ChatGPT 客户端连接状态
                HStack(spacing: 8) {
                    Circle()
                        .fill(quotaEngine.currentQuota.isConnectedToChatGPTApp ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    if quotaEngine.currentQuota.isConnectedToChatGPTApp {
                        Text("已连接本地 ChatGPT 客户端 (PID: \(quotaEngine.currentQuota.chatGPTPid ?? 0))")
                            .font(.caption.bold())
                            .foregroundStyle(.green)
                    } else {
                        Text("本地 ChatGPT.app 未运行 (无影响，Next5h 通过底层 Token 独立监控与派发)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .controlBackgroundColor).opacity(0.6)))
                .padding(.horizontal, 20)
                
                // 100% 对齐官方“剩余”逻辑的双卡片 (垂直排列以适应 Setting 紧凑宽度)
                VStack(spacing: 12) {
                    // 1. 5 小时滑动窗口主卡片
                    let remaining5h = quotaEngine.currentQuota.remainingPercent
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("5 小时滑动周期窗口 (300m)")
                                    .font(.headline)
                                Text("当前剩余 \(String(format: "%.1f", remaining5h))% · 已用 \(String(format: "%.1f", quotaEngine.currentQuota.usedPercent))%")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("剩余 \(String(format: "%.1f", remaining5h))%")
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
                                Text("解锁时间 (Resets At)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                if let resetsAt = quotaEngine.currentQuota.resetsAt {
                                    Text(formatDateTime(resetsAt))
                                        .font(.caption.bold())
                                } else {
                                    Text("未受限")
                                        .font(.caption)
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("剩余倒计时")
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
                                Text("7 天每周额度窗口 (7 Days)")
                                    .font(.headline)
                                Text("当前剩余 \(String(format: "%.1f", weeklyRem))% · 已用 \(String(format: "%.1f", weeklyUsed))%")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("剩余 \(String(format: "%.1f", weeklyRem))%")
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
                                Text("周重置时间")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                if let wReset = quotaEngine.currentQuota.weeklyResetsAt {
                                    Text(formatDateTime(wReset))
                                        .font(.caption.bold())
                                } else {
                                    Text("每周循环")
                                        .font(.caption)
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("周周期倒计时")
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
                .padding(.horizontal, 20)
                
                // 探针运行日志
                ProbeLogView()
                    .padding(.horizontal, 20)
                
                // 系统权限与健康状态
                PermissionsCardView()
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }
        }
        .scrollContentBackground(.hidden)
    }
}
