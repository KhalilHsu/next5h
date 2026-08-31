import Foundation
import Combine

public final class JobQueueManager: ObservableObject {
    public static let shared = JobQueueManager()
    
    @Published public var jobs: [ScheduledJob] = []
    
    private var cancellables = Set<AnyCancellable>()
    private var schedulerTimer: Timer?
    
    private init() {
        loadPersistedJobs()
        startDispatchLoop()
    }
    
    private var persistenceURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Next5h")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("scheduled_jobs.json")
    }
    
    private func loadPersistedJobs() {
        if let data = try? Data(contentsOf: persistenceURL),
           let saved = try? JSONDecoder().decode([ScheduledJob].self, from: data),
           !saved.isEmpty {
            // 自动确保所有待发任务都有精确计算的未来执行时间
            self.jobs = saved.map { job in
                var j = job
                if j.status == .pending {
                    if j.scheduledExecutionDate == nil || j.scheduledExecutionDate! <= Date() {
                        let nextDate = SmartScheduler.shared.calculateNextExecutionDate(
                            for: j.strategy,
                            currentQuota: QuotaProbeEngine.shared.currentQuota
                        )
                        j.scheduledExecutionDate = nextDate
                        _ = PowerGuardian.shared.scheduleWakeEvent(at: nextDate)
                    }
                }
                return j
            }
            saveJobs()
        } else {
            // 首次启动：预填精确到具体时间的 07:00 默认任务
            let initialPreset = ScheduledJob.makeDefaultPreset()
            if let sched = initialPreset.scheduledExecutionDate {
                _ = PowerGuardian.shared.scheduleWakeEvent(at: sched)
            }
            self.jobs = [initialPreset]
            saveJobs()
        }
    }
    
    public func saveJobs() {
        if let data = try? JSONEncoder().encode(jobs) {
            try? data.write(to: persistenceURL)
        }
    }
    
    public func addJob(_ job: ScheduledJob) {
        var newJob = job
        let nextDate = SmartScheduler.shared.calculateNextExecutionDate(
            for: newJob.strategy,
            currentQuota: QuotaProbeEngine.shared.currentQuota
        )
        newJob.scheduledExecutionDate = nextDate
        newJob.status = .pending
        
        // 注册硬件级 RTC 唤醒
        _ = PowerGuardian.shared.scheduleWakeEvent(at: nextDate)
        
        jobs.insert(newJob, at: 0)
        saveJobs()
    }
    
    public func updateJob(_ job: ScheduledJob) {
        if let index = jobs.firstIndex(where: { $0.id == job.id }) {
            var updated = job
            let nextDate = SmartScheduler.shared.calculateNextExecutionDate(
                for: updated.strategy,
                currentQuota: QuotaProbeEngine.shared.currentQuota
            )
            updated.scheduledExecutionDate = nextDate
            updated.status = .pending
            
            // 重新注册硬件级 RTC 唤醒
            _ = PowerGuardian.shared.scheduleWakeEvent(at: nextDate)
            
            jobs[index] = updated
            saveJobs()
            print("💾 [JobQueueManager] 已成功保存并更新任务: \(updated.title), 下次执行时间: \(nextDate)")
        } else {
            addJob(job)
        }
    }
    
    public func deleteJob(id: UUID) {
        jobs.removeAll(where: { $0.id == id })
        saveJobs()
    }
    
    public func togglePause(id: UUID) {
        if let index = jobs.firstIndex(where: { $0.id == id }) {
            if case .paused = jobs[index].status {
                jobs[index].status = .pending
                let nextDate = SmartScheduler.shared.calculateNextExecutionDate(
                    for: jobs[index].strategy,
                    currentQuota: QuotaProbeEngine.shared.currentQuota
                )
                jobs[index].scheduledExecutionDate = nextDate
                _ = PowerGuardian.shared.scheduleWakeEvent(at: nextDate)
            } else {
                jobs[index].status = .paused
            }
            saveJobs()
        }
    }
    
    /// 调度主循环（每 5 秒检测一次队列中的到期任务）
    private func startDispatchLoop() {
        schedulerTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkAndExecuteDueJobs()
        }
    }
    
    public func checkAndExecuteDueJobs() {
        let now = Date()
        for index in jobs.indices {
            let job = jobs[index]
            guard job.status == .pending || job.status == .waitingForQuota,
                  let sched = job.scheduledExecutionDate,
                  now >= sched else {
                continue
            }
            
            // 触发执行该任务
            executeJob(jobId: job.id)
        }
    }
    
    public func executeJob(jobId: UUID) {
        guard let index = jobs.firstIndex(where: { $0.id == jobId }) else { return }
        let job = jobs[index]
        
        jobs[index].status = .sending
        saveJobs()
        
        Task {
            // 1. 获取电源断言（防止 Mac 睡着）
            PowerGuardian.shared.acquireSleepAssertion(reason: "Next5h 发送任务: \(job.title)")
            
            // 2. 等待网络就绪（若刚被唤醒）
            _ = await NetworkMonitor.shared.waitForNetworkReadiness()
            
            // 3. 根据分发模式派发
            let startTime = Date()
            var isSuccessful = false
            var errorDetail: String? = nil
            do {
                if job.dispatchMode == .silentAPI {
                    isSuccessful = try await SilentAPIDispatcher.shared.dispatch(job: job)
                } else {
                    isSuccessful = try await ForegroundUIDispatcher.shared.dispatch(job: job)
                }
                if !isSuccessful {
                    errorDetail = "派发返回失败或发生网络异常"
                }
            } catch {
                errorDetail = error.localizedDescription
                print("⚠️ [JobQueueManager] 派发异常: \(error)")
            }
            
            let duration = Date().timeIntervalSince(startTime)
            let finalSuccess = isSuccessful
            let finalError = errorDetail
            
            // 4. 生成历史记录并保存
            let historyRecord = DispatchHistoryRecord(
                jobId: job.id,
                title: job.title,
                prompt: job.prompt,
                dispatchedAt: startTime,
                durationSeconds: duration,
                isSuccess: finalSuccess,
                errorMessage: finalError,
                modelSlug: job.model.slug,
                modelDisplayName: job.model.displayName,
                reasoningEffort: job.reasoningEffort.displayName,
                speed: job.speed.displayName,
                destinationSummary: job.destination.summary,
                targetSessionId: {
                    if case .existing(let tid, _) = job.destination.conversationAction {
                        return tid
                    }
                    return nil
                }(),
                dispatchMode: job.dispatchMode,
                triggerStrategySummary: job.strategy.displayName
            )
            
            // 5. 更新任务状态与每日循环调度
            await MainActor.run {
                DispatchHistoryManager.shared.addRecord(historyRecord)
                
                if let idx = self.jobs.firstIndex(where: { $0.id == jobId }) {
                    if finalSuccess {
                        self.jobs[idx].executedAt = Date()
                        NotificationService.shared.sendCompletionNotification(for: self.jobs[idx])
                        
                        // 🌟 核心：如果是每日定时重复任务 (dailyAtTime)，自动计算并排定明天的下一次执行时间，保持 pending 状态
                        if case .dailyAtTime = self.jobs[idx].strategy {
                            let tomorrowDate = SmartScheduler.shared.calculateNextExecutionDate(
                                for: self.jobs[idx].strategy,
                                currentQuota: QuotaProbeEngine.shared.currentQuota
                            )
                            self.jobs[idx].scheduledExecutionDate = tomorrowDate
                            self.jobs[idx].status = .pending
                            
                            // 重新注册明天的硬件级 RTC 唤醒
                            _ = PowerGuardian.shared.scheduleWakeEvent(at: tomorrowDate)
                            print("🔄 [JobQueueManager] 每日任务 [\(self.jobs[idx].title)] 执行完成，已自动排定明天执行时间: \(tomorrowDate)")
                        } else {
                            self.jobs[idx].status = .completed(Date())
                        }
                    } else {
                        self.jobs[idx].status = .failed(finalError ?? "发送失败或发生网络异常")
                    }
                    self.saveJobs()
                }
                
                // 6. 释放电源断言
                PowerGuardian.shared.releaseSleepAssertion()
            }
        }
    }
    
    /// 直接执行一次性派发（用于历史记录的“再次发送”）
    public func executeDirectJob(_ job: ScheduledJob) {
        Task {
            PowerGuardian.shared.acquireSleepAssertion(reason: "Next5h 再次发送任务: \(job.title)")
            _ = await NetworkMonitor.shared.waitForNetworkReadiness()
            
            let startTime = Date()
            var isSuccessful = false
            var errorDetail: String? = nil
            do {
                if job.dispatchMode == .silentAPI {
                    isSuccessful = try await SilentAPIDispatcher.shared.dispatch(job: job)
                } else {
                    isSuccessful = try await ForegroundUIDispatcher.shared.dispatch(job: job)
                }
                if !isSuccessful {
                    errorDetail = "派发返回失败或发生网络异常"
                }
            } catch {
                errorDetail = error.localizedDescription
                print("⚠️ [JobQueueManager] 直接派发异常: \(error)")
            }
            
            let duration = Date().timeIntervalSince(startTime)
            let finalSuccess = isSuccessful
            let finalError = errorDetail
            
            let historyRecord = DispatchHistoryRecord(
                jobId: job.id,
                title: job.title,
                prompt: job.prompt,
                dispatchedAt: startTime,
                durationSeconds: duration,
                isSuccess: finalSuccess,
                errorMessage: finalError,
                modelSlug: job.model.slug,
                modelDisplayName: job.model.displayName,
                reasoningEffort: job.reasoningEffort.displayName,
                speed: job.speed.displayName,
                destinationSummary: job.destination.summary,
                targetSessionId: {
                    if case .existing(let tid, _) = job.destination.conversationAction {
                        return tid
                    }
                    return nil
                }(),
                dispatchMode: job.dispatchMode,
                triggerStrategySummary: "手动再次发送"
            )
            
            await MainActor.run {
                DispatchHistoryManager.shared.addRecord(historyRecord)
                if finalSuccess {
                    NotificationService.shared.sendCompletionNotification(for: job)
                }
                PowerGuardian.shared.releaseSleepAssertion()
            }
        }
    }
}
