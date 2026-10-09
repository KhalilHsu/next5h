import Foundation
import Combine

public final class JobQueueManager: ObservableObject {
    public static let shared = JobQueueManager()
    
    @Published public var jobs: [ScheduledJob] = []
    
    private var cancellables = Set<AnyCancellable>()
    private var schedulerTimer: Timer?
    private let storageURL: URL?
    private let preferences: UserDefaults
    private let startsScheduling: Bool
    private static let continuationPresetKey = "installedQuotaContinuationPreset.v1"
    
    init(persistenceURL: URL? = nil, preferences: UserDefaults = .standard, startsScheduling: Bool = true) {
        self.storageURL = persistenceURL
        self.preferences = preferences
        self.startsScheduling = startsScheduling
        loadPersistedJobs()
        if startsScheduling {
            startDispatchLoop()
            QuotaProbeEngine.shared.$currentQuota
                .receive(on: RunLoop.main)
                .sink { [weak self] quota in self?.scheduleWaitingContinuations(currentQuota: quota) }
                .store(in: &cancellables)
        }
    }

    deinit {
        schedulerTimer?.invalidate()
    }
    
    private var persistenceURL: URL {
        if let storageURL { return storageURL }
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Next5h")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("scheduled_jobs.json")
    }
    
    private func loadPersistedJobs() {
        if let data = try? Data(contentsOf: persistenceURL),
           let saved = try? JSONDecoder().decode([ScheduledJob].self, from: data) {
            // 自动确保所有待发任务都有精确计算的未来执行时间，并自动清理已完成的一次性历史任务
            self.jobs = saved.compactMap { job in
                if case .completed = job.status {
                    return nil // 已完成任务已在历史留痕中，队列中不再保留
                }
                var j = job
                if !j.hasValidDestination || !j.isEnabled {
                    j.status = .paused
                    j.scheduledExecutionDate = nil
                    return j
                }
                // 每日定时任务自愈：若任务为每日定时任务且处于 failed 状态，自动恢复为 pending 并重置为下次执行时间
                if case .dailyAtTime = j.strategy, case .failed = j.status {
                    let nextDate = SmartScheduler.shared.calculateNextExecutionDate(
                        for: j.strategy,
                        currentQuota: QuotaProbeEngine.shared.currentQuota
                    )
                    j.scheduledExecutionDate = nextDate
                    j.status = .pending
                    registerWake(at: nextDate)
                    print("🔄 [JobQueueManager] 检测到每日任务 [\(j.title)] 处于失败状态，已自动重置排程至: \(nextDate)")
                } else if j.status == .pending {
                    if j.scheduledExecutionDate == nil || j.scheduledExecutionDate! <= Date() {
                        j = preparedForScheduling(j, currentQuota: QuotaProbeEngine.shared.currentQuota)
                    }
                }
                return j
            }
        } else {
            // 首次启动：预填精确到具体时间的 07:00 默认任务
            let initialPreset = ScheduledJob.makeDefaultPreset()
            if let sched = initialPreset.scheduledExecutionDate {
                registerWake(at: sched)
            }
            self.jobs = [initialPreset]
        }

        // Install this disabled starter once, without replacing existing jobs or restoring a deleted starter.
        let needsContinuationPreset = !preferences.bool(forKey: Self.continuationPresetKey)
        if needsContinuationPreset, !jobs.contains(where: { $0.templateKind == .quotaContinuation }) {
            jobs.append(ScheduledJob.makeQuotaContinuationPreset())
        }
        if saveJobs(), needsContinuationPreset {
            preferences.set(true, forKey: Self.continuationPresetKey)
        }
    }
    
    @discardableResult
    public func saveJobs() -> Bool {
        let saved: Bool
        do {
            try JSONEncoder().encode(jobs).write(to: persistenceURL, options: .atomic)
            saved = true
        } catch {
            saved = false
        }
        syncPowerAssertionState()
        return saved
    }
    
    /// 自动同步系统待命电源断言状态
    /// 只要队列中存在待派发的定时任务，自动保持系统息屏运行，杜绝休眠冻结导致无法准时派发
    public func syncPowerAssertionState() {
        guard startsScheduling else { return }
        let hasPending = jobs.contains { job in
            (job.status == .pending || job.status == .waitingForQuota) &&
            job.scheduledExecutionDate != nil
        }
        PowerGuardian.shared.updateStandbyAssertion(hasPendingJobs: hasPending)
    }
    
    public func addJob(_ job: ScheduledJob) {
        let newJob = preparedForScheduling(job, currentQuota: QuotaProbeEngine.shared.currentQuota)
        jobs.insert(newJob, at: 0)
        saveJobs()
    }
    
    public func updateJob(_ job: ScheduledJob) {
        if let index = jobs.firstIndex(where: { $0.id == job.id }) {
            guard jobs[index].status != .sending else { return }
            let updated = preparedForScheduling(job, currentQuota: QuotaProbeEngine.shared.currentQuota)
            jobs[index] = updated
            saveJobs()
        } else {
            addJob(job)
        }
    }
    
    public func deleteJob(id: UUID) {
        jobs.removeAll(where: { $0.id == id })
        saveJobs()
    }
    
    public func togglePause(id: UUID) {
        guard let job = jobs.first(where: { $0.id == id }) else { return }
        setJobEnabled(id: id, enabled: !job.isEnabled)
    }

    @discardableResult
    public func setJobEnabled(id: UUID, enabled: Bool) -> Bool {
        guard let index = jobs.firstIndex(where: { $0.id == id }),
              jobs[index].status != .sending,
              !enabled || jobs[index].hasValidDestination else { return false }
        if jobs[index].isEnabled == enabled { return true }
        jobs[index].status = enabled ? .pending : .paused
        jobs[index] = preparedForScheduling(jobs[index], currentQuota: QuotaProbeEngine.shared.currentQuota)
        saveJobs()
        return true
    }

    private func registerWake(at date: Date) {
        if startsScheduling { _ = PowerGuardian.shared.scheduleWakeEvent(at: date) }
    }

    func preparedForScheduling(_ job: ScheduledJob, currentQuota: QuotaSnapshot) -> ScheduledJob {
        var scheduled = job
        guard job.isEnabled, job.hasValidDestination else {
            scheduled.status = .paused
            scheduled.scheduledExecutionDate = nil
            return scheduled
        }
        if job.templateKind == .quotaContinuation,
           case .autoOnQuotaReset = job.strategy,
           currentQuota.resetsAt == nil {
            scheduled.status = .waitingForQuota
            scheduled.scheduledExecutionDate = nil
        } else {
            let date = SmartScheduler.shared.calculateNextExecutionDate(for: job.strategy, currentQuota: currentQuota)
            scheduled.status = .pending
            scheduled.scheduledExecutionDate = date
            registerWake(at: date)
        }
        return scheduled
    }

    /// Missing quota data must never turn a continuation into an immediate send.
    func scheduleWaitingContinuations(currentQuota: QuotaSnapshot) {
        guard currentQuota.resetsAt != nil else { return }
        var changed = false
        for index in jobs.indices {
            let job = jobs[index]
            if job.templateKind == .quotaContinuation, job.status == .waitingForQuota,
               job.scheduledExecutionDate == nil, case .autoOnQuotaReset = job.strategy {
                jobs[index] = preparedForScheduling(job, currentQuota: currentQuota)
                changed = true
            }
        }
        if changed { saveJobs() }
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
        guard let index = jobs.firstIndex(where: { $0.id == jobId }),
              jobs[index].status != .sending, jobs[index].hasValidDestination else { return }
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
                strategy: job.strategy,
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
                            // A manual send while disabled must not re-enable the daily schedule.
                            self.jobs[idx].status = job.isEnabled ? .pending : .paused
                            self.jobs[idx] = self.preparedForScheduling(self.jobs[idx], currentQuota: QuotaProbeEngine.shared.currentQuota)
                        } else {
                            // 一次性任务派发成功后已沉淀到历史记录，自动从待发调度队列移除
                            let removedJob = self.jobs.remove(at: idx)
                            print("✅ [JobQueueManager] 一次性任务 [\(removedJob.title)] 派发成功，已移出待发调度队列")
                        }
                    } else {
                        if case .dailyAtTime = self.jobs[idx].strategy {
                            // 每日重复任务即使单次派发异常（已在消息历史中记录），也自动排定明天同一时刻执行，防止单次错误造成周期无限停滞
                            self.jobs[idx].status = job.isEnabled ? .pending : .paused
                            self.jobs[idx] = self.preparedForScheduling(self.jobs[idx], currentQuota: QuotaProbeEngine.shared.currentQuota)
                        } else {
                            self.jobs[idx].status = .failed(finalError ?? "发送失败或发生网络异常")
                        }
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
                strategy: job.strategy,
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
