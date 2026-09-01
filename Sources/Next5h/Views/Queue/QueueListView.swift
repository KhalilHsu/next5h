import SwiftUI

public struct QueueListView: View {
    @ObservedObject private var queueManager = JobQueueManager.shared
    @ObservedObject private var appState = AppState.shared
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 顶部标题与状态摘要栏
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 7) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.secondary)

                        Text("任务调度队列")
                            .font(.title3.bold())
                        
                        if !queueManager.jobs.isEmpty {
                            Text("\(queueManager.jobs.count) 项待执行")
                                .font(.caption.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.secondary.opacity(0.12)))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Text("到点自动唤醒 Mac 并在后台向本地 Codex 客户端派发 User Query，免去守候与频繁手动操作")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button {
                    appState.openNewJobSheet()
                } label: {
                    Label("新建任务", systemImage: "plus")
                        .font(.subheadline.bold())
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // 电源与休眠唤醒状态保障提示
            PowerQuickTipBanner()
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            
            Divider()
            
            // 列表主体 / 空白引导态
            if queueManager.jobs.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 38, weight: .light))
                        .foregroundStyle(.tertiary)
                    
                    Text("当前暂无排定的自动化任务")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text("您可以创建早晨定时打卡、5H 额度解封自动发送或延时问询等任务。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button {
                        appState.openNewJobSheet()
                    } label: {
                        Label("新建任务", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .padding(.top, 4)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List {
                    ForEach(queueManager.jobs) { job in
                        QueueJobCardView(job: job)
                            .padding(.vertical, 4)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

struct QueueJobCardView: View {
    let job: ScheduledJob
    @ObservedObject private var queueManager = JobQueueManager.shared
    @ObservedObject private var appState = AppState.shared
    
    private func formatDateTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "今天 HH:mm:ss"
        } else if calendar.isDateInTomorrow(date) {
            formatter.dateFormat = "明天 HH:mm:ss"
        } else {
            formatter.dateFormat = "MM-dd HH:mm"
        }
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 1. 顶部状态与标题
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: job.status.iconName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(statusColor(job.status))
                
                Text(job.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                // 状态文本
                Text(job.status.statusName)
                    .font(.caption2.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(statusColor(job.status).opacity(0.12)))
                    .foregroundStyle(statusColor(job.status))
                
                // 模型与推理强度标签
                Text("\(job.model.displayName) \(job.reasoningEffort.shortLabel)")
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.orange.opacity(0.15)))
                    .foregroundStyle(.orange)
            }
            
            // 2. Prompt 内容预览
            Text(job.prompt)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.primary.opacity(0.9))
                .lineLimit(2)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color(nsColor: .textBackgroundColor).opacity(0.7)))
            
            // 3. 元信息属性栏 (目标、派发模式、下次执行时间)
            HStack(spacing: 12) {
                Label(job.destination.summary, systemImage: "folder")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Text("•")
                    .font(.caption2)
                    .foregroundStyle(.secondary.opacity(0.5))
                
                Label(job.dispatchMode == .silentAPI ? "静默 CLI" : "前台 GUI", systemImage: "paperplane")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if let sched = job.scheduledExecutionDate {
                    HStack(spacing: 4) {
                        if case .dailyAtTime(let h, let m) = job.strategy {
                            Image(systemName: "repeat")
                                .font(.system(size: 9))
                            Text("每天 \(String(format: "%02d:%02d", h, m)) · 下次: \(formatDateTime(sched))")
                        } else {
                            Image(systemName: "clock")
                                .font(.system(size: 9))
                            Text("预定: \(formatDateTime(sched))")
                        }
                    }
                    .font(.caption2.bold())
                    .foregroundStyle(.orange)
                }
            }
            
            Divider()
                .padding(.vertical, 2)
            
            // 4. 底部操作按钮栏
            HStack(spacing: 14) {
                Button {
                    queueManager.executeJob(jobId: job.id)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "play.circle.fill")
                        Text("立即发送")
                    }
                    .font(.caption.bold())
                }
                .buttonStyle(.borderless)
                
                Button {
                    appState.openEditJobSheet(job: job)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                        Text("编辑")
                    }
                    .font(.caption)
                }
                .buttonStyle(.borderless)
                
                Button {
                    queueManager.togglePause(id: job.id)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: job.status == .paused ? "arrow.clockwise" : "pause.circle")
                        Text(job.status == .paused ? "恢复排程" : "暂停")
                    }
                    .font(.caption)
                    .foregroundStyle(job.status == .paused ? .green : .secondary)
                }
                .buttonStyle(.borderless)
                
                Spacer()
                
                Button(role: .destructive) {
                    queueManager.deleteJob(id: job.id)
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(nsColor: .controlBackgroundColor).opacity(0.8)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.15), lineWidth: 1))
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            appState.openEditJobSheet(job: job)
        }
        .contextMenu {
            Button {
                queueManager.executeJob(jobId: job.id)
            } label: {
                Label("立即发送", systemImage: "play.fill")
            }
            
            Button {
                appState.openEditJobSheet(job: job)
            } label: {
                Label("编辑任务...", systemImage: "pencil")
            }
            
            Button {
                queueManager.togglePause(id: job.id)
            } label: {
                Label(job.status == .paused ? "恢复排程" : "暂停", systemImage: job.status == .paused ? "play.fill" : "pause.fill")
            }
            
            Divider()
            
            Button(role: .destructive) {
                queueManager.deleteJob(id: job.id)
            } label: {
                Label("删除任务", systemImage: "trash")
            }
        }
    }
    
    private func statusColor(_ status: JobStatus) -> Color {
        switch status {
        case .pending, .waitingForQuota: return .orange
        case .sending: return .blue
        case .completed: return .green
        case .failed: return .red
        case .paused: return .secondary
        }
    }
}
