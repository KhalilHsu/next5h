import SwiftUI

public struct QueueListView: View {
    @ObservedObject private var queueManager = JobQueueManager.shared
    @ObservedObject private var appState = AppState.shared
    @ObservedObject private var loc = LocalizationManager.shared
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // 顶部标题与状态摘要栏
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 7) {
                            Image(systemName: "list.bullet.rectangle")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.secondary)

                            Text(L10n.queueTitle)
                                .font(.title3.bold())
                            
                            if !queueManager.jobs.isEmpty {
                                Text(L10n.queuePendingCount(queueManager.jobs.count))
                                    .font(.caption.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(Color.secondary.opacity(0.12)))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Text(L10n.queueSubtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                    
                    Button {
                        appState.openNewJobSheet()
                    } label: {
                        Label(L10n.queueNewMessage, systemImage: "plus")
                            .font(.subheadline.bold())
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                }
                .padding(.top, 14)
                .padding(.bottom, 2)
                
                // 电源与休眠唤醒状态保障提示 (无多余分割线，左右严格对齐)
                PowerQuickTipBanner()
                
                // 任务卡片列表 (使用 LazyVStack 保证与顶部各元素 100% 像素级对齐)
                if queueManager.jobs.isEmpty {
                    VStack(spacing: 12) {
                        Spacer().frame(height: 36)
                        
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 38, weight: .light))
                            .foregroundStyle(.tertiary)
                        
                        Text(L10n.queueEmptyTitle)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text(L10n.queueEmptySubtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button {
                            appState.openNewJobSheet()
                        } label: {
                            Label(L10n.queueNewMessage, systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                        .padding(.top, 4)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(queueManager.jobs) { job in
                            QueueJobCardView(job: job)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .padding(.horizontal, 24)
        }
        .scrollContentBackground(.hidden)
    }
}

struct QueueJobCardView: View {
    let job: ScheduledJob
    @ObservedObject private var queueManager = JobQueueManager.shared
    @ObservedObject private var appState = AppState.shared
    @ObservedObject private var loc = LocalizationManager.shared
    
    private func formatDateTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "\(L10n.dateToday) HH:mm:ss"
        } else if calendar.isDateInTomorrow(date) {
            formatter.dateFormat = "\(L10n.dateTomorrow) HH:mm:ss"
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
                
                Label(job.dispatchMode == .silentAPI
                      ? L10n.tr(zh: "静默 CLI", en: "Silent CLI", ja: "サイレント CLI")
                      : L10n.tr(zh: "前台 GUI", en: "Foreground GUI", ja: "前面 GUI"),
                      systemImage: "paperplane")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if let sched = job.scheduledExecutionDate {
                    HStack(spacing: 4) {
                        if case .dailyAtTime(let h, let m) = job.strategy {
                            Image(systemName: "repeat")
                                .font(.system(size: 9))
                            Text(L10n.tr(
                                zh: "每天 \(String(format: "%02d:%02d", h, m)) · 下次: \(formatDateTime(sched))",
                                en: "Daily \(String(format: "%02d:%02d", h, m)) · Next: \(formatDateTime(sched))",
                                ja: "毎日 \(String(format: "%02d:%02d", h, m)) · 次回: \(formatDateTime(sched))"
                            ))
                        } else {
                            Image(systemName: "clock")
                                .font(.system(size: 9))
                            Text(L10n.tr(
                                zh: "预定: \(formatDateTime(sched))",
                                en: "Scheduled: \(formatDateTime(sched))",
                                ja: "予定: \(formatDateTime(sched))"
                            ))
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
                        Text(L10n.actionSendNow)
                    }
                    .font(.caption.bold())
                }
                .buttonStyle(.borderless)
                
                Button {
                    appState.openEditJobSheet(job: job)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                        Text(L10n.actionEdit)
                    }
                    .font(.caption)
                }
                .buttonStyle(.borderless)
                
                Button {
                    queueManager.togglePause(id: job.id)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: job.status == .paused ? "arrow.clockwise" : "pause.circle")
                        Text(job.status == .paused
                             ? L10n.tr(zh: "恢复排程", en: "Resume", ja: "再開")
                             : L10n.tr(zh: "暂停", en: "Pause", ja: "一時停止"))
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
        .background(RoundedRectangle(cornerRadius: 11).fill(Color(nsColor: .controlBackgroundColor).opacity(0.55)))
        .overlay(RoundedRectangle(cornerRadius: 11).stroke(Color.primary.opacity(0.08), lineWidth: 0.8))
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            appState.openEditJobSheet(job: job)
        }
        .contextMenu {
            Button {
                queueManager.executeJob(jobId: job.id)
            } label: {
                Label(L10n.actionSendNow, systemImage: "play.fill")
            }
            
            Button {
                appState.openEditJobSheet(job: job)
            } label: {
                Label(L10n.tr(zh: "编辑任务...", en: "Edit Task...", ja: "タスクを編集..."), systemImage: "pencil")
            }
            
            Button {
                queueManager.togglePause(id: job.id)
            } label: {
                Label(job.status == .paused
                      ? L10n.tr(zh: "恢复排程", en: "Resume", ja: "再開")
                      : L10n.tr(zh: "暂停", en: "Pause", ja: "一時停止"),
                      systemImage: job.status == .paused ? "play.fill" : "pause.fill")
            }
            
            Divider()
            
            Button(role: .destructive) {
                queueManager.deleteJob(id: job.id)
            } label: {
                Label(L10n.tr(zh: "删除任务", en: "Delete Task", ja: "タスクを削除"), systemImage: "trash")
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
