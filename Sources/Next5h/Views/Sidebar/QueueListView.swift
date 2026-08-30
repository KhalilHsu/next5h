import SwiftUI

public struct QueueListView: View {
    @ObservedObject private var queueManager = JobQueueManager.shared
    @ObservedObject private var appState = AppState.shared
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("📋 任务调度队列")
                    .font(.headline)
                Spacer()
                Text("\(queueManager.jobs.count) 个任务")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
            
            // 电源与休眠唤醒状态小贴士
            PowerQuickTipBanner()
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            
            if queueManager.jobs.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "tray")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("当前暂无排定任务")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("➕ 创建新任务") {
                        appState.selectedTab = .composer
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List {
                    ForEach(queueManager.jobs) { job in
                        JobRowView(job: job)
                            .padding(.vertical, 4)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    queueManager.deleteJob(id: job.id)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                                
                                Button {
                                    queueManager.togglePause(id: job.id)
                                } label: {
                                    Label(job.status == .paused ? "恢复" : "暂停", systemImage: job.status == .paused ? "play.fill" : "pause.fill")
                                }
                            }
                    }
                }
                .listStyle(.inset)
            }
        }
    }
}

struct JobRowView: View {
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: job.status.iconName)
                    .foregroundStyle(statusColor(job.status))
                
                Text(job.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                Text("\(job.model.displayName) \(job.reasoningEffort.displayName)")
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.orange.opacity(0.15)))
                    .foregroundStyle(.orange)
            }
            
            Text(job.prompt)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            
            HStack {
                Label(job.destination.summary, systemImage: "folder")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if let sched = job.scheduledExecutionDate {
                    HStack(spacing: 4) {
                        if case .dailyAtTime = job.strategy {
                            Image(systemName: "repeat")
                                .font(.system(size: 9))
                        }
                        Text("预定: \(formatDateTime(sched))")
                    }
                    .font(.caption2.bold())
                    .foregroundStyle(.orange)
                }
            }
            
            Divider()
                .padding(.vertical, 2)
            
            // 操作栏与状态标识
            HStack {
                HStack(spacing: 4) {
                    Text(job.status.statusName)
                        .font(.caption.bold())
                        .foregroundStyle(statusColor(job.status))
                    
                    if case .dailyAtTime(let h, let m) = job.strategy {
                        Text("(每天 \(String(format: "%02d:%02d", h, m)) 循环)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Button("立即发送") {
                    queueManager.executeJob(jobId: job.id)
                }
                .buttonStyle(.borderless)
                .font(.caption.bold())
                
                Button("编辑") {
                    appState.editingJob = job
                    appState.selectedTab = .composer
                }
                .buttonStyle(.borderless)
                .font(.caption)
                
                Button("删除") {
                    queueManager.deleteJob(id: job.id)
                }
                .buttonStyle(.borderless)
                .font(.caption)
                .foregroundStyle(.red)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(nsColor: .controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.15), lineWidth: 1))
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
