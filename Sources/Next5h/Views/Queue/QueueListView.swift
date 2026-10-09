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
                            Text(L10n.queueTitle)
                                .font(.system(size: 21, weight: .semibold))
                            
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
                        Next5hButtonLabel(L10n.queueNewMessage, systemImage: "plus")
                    }
                    .buttonStyle(Next5hButtonStyle(kind: .primary))
                    .controlSize(.regular)
                }
                .padding(.top, 24)
                .padding(.bottom, 10)
                
                // 电源与休眠唤醒状态保障提示 (无多余分割线，左右严格对齐)

                
                // 任务卡片列表 (使用 LazyVStack 保证与顶部各元素 100% 像素级对齐)
                if queueManager.jobs.isEmpty {
                    VStack(spacing: 12) {
                        Spacer().frame(height: 36)
                        
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 28, weight: .light))
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
                            Next5hButtonLabel(L10n.queueNewMessage, systemImage: "plus")
                        }
                        .buttonStyle(Next5hButtonStyle(kind: .primary))
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
            formatter.dateFormat = "\(L10n.dateToday) HH:mm"
        } else if calendar.isDateInTomorrow(date) {
            formatter.dateFormat = "\(L10n.dateTomorrow) HH:mm"
        } else {
            formatter.dateFormat = "MM-dd HH:mm"
        }
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text(job.title)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(2)
                Spacer(minLength: 8)
                Label(job.status.statusName, systemImage: job.status.iconName)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(statusColor(job.status))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(statusColor(job.status).opacity(0.10), in: RoundedRectangle(cornerRadius: 5))
            }

            Text(job.prompt)
                .font(.system(size: 13))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 2)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) { metadata }
                VStack(alignment: .leading, spacing: 5) { metadata }
            }
            .font(.caption)
            .foregroundStyle(Next5hTheme.secondary)

            Divider().overlay(Next5hTheme.border)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) {
                    scheduleSummary
                    Spacer(minLength: 10)
                    actions
                }
                VStack(alignment: .leading, spacing: 10) {
                    scheduleSummary
                    actions
                }
            }
        }
        .next5hSurface(padding: 18)
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(statusColor(job.status))
                .frame(width: 3)
                .padding(.vertical, 14)
        }
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
    
    @ViewBuilder
    private var metadata: some View {
        Label(job.destination.summary, systemImage: "folder")
        Text("\(job.model.displayName) · \(job.reasoningEffort.shortLabel)")
        Text(job.dispatchMode == .silentAPI
             ? L10n.tr(zh: "后台发送", en: "Background", ja: "バックグラウンド送信")
             : L10n.tr(zh: "前台发送", en: "Foreground", ja: "前面送信"))
    }

    private var scheduleSummary: some View {
        VStack(alignment: .leading, spacing: 3) {
            if let date = job.scheduledExecutionDate {
                Label(formatDateTime(date), systemImage: "clock")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Next5hTheme.accent)
                    .monospacedDigit()
            }
            Text(job.strategy.displayName)
                .font(.caption2)
                .foregroundStyle(Next5hTheme.secondary)
        }
    }

    private var actions: some View {
        HStack(spacing: Next5hButtonMetrics.groupSpacing) {
            Button { queueManager.executeJob(jobId: job.id) } label: {
                Next5hButtonLabel(L10n.actionSendNow, systemImage: "play.circle")
            }
            Button { appState.openEditJobSheet(job: job) } label: {
                Next5hButtonLabel(L10n.actionEdit, systemImage: "pencil")
            }
            Button { queueManager.togglePause(id: job.id) } label: {
                Next5hButtonLabel(job.status == .paused
                      ? L10n.tr(zh: "恢复排程", en: "Resume", ja: "再開")
                      : L10n.tr(zh: "暂停", en: "Pause", ja: "一時停止"),
                      systemImage: job.status == .paused ? "arrow.clockwise" : "pause.circle")
            }
            Button(role: .destructive) { queueManager.deleteJob(id: job.id) } label: {
                Next5hButtonLabel(systemImage: "trash")
            }
            .buttonStyle(Next5hButtonStyle(kind: .quiet, iconOnly: true))
            .help(L10n.tr(zh: "删除任务", en: "Delete Task", ja: "タスクを削除"))
        }
        .buttonStyle(Next5hButtonStyle(kind: .quiet))
    }

    private func statusColor(_ status: JobStatus) -> Color {
        switch status {
        case .pending: return Next5hTheme.accent
        case .waitingForQuota: return Next5hTheme.warning
        case .sending: return Next5hTheme.accent
        case .completed: return Next5hTheme.mint
        case .failed: return .red
        case .paused: return .secondary
        }
    }
}
