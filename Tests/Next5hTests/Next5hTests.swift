import XCTest
import AppKit
@testable import Next5h

final class Next5hTests: XCTestCase {
    private func withIsolatedQueue(initialJobs: [ScheduledJob]? = nil, _ body: (JobQueueManager, URL, UserDefaults) throws -> Void) throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("Next5hTests-\(UUID())")
        let suite = "Next5hTests.\(UUID())"
        let preferences = try XCTUnwrap(UserDefaults(suiteName: suite))
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: folder)
            preferences.removePersistentDomain(forName: suite)
        }
        let url = folder.appendingPathComponent("jobs.json")
        if let initialJobs {
            try JSONEncoder().encode(initialJobs).write(to: url)
        }
        let queue = JobQueueManager(persistenceURL: url, preferences: preferences, startsScheduling: false)
        try body(queue, url, preferences)
    }

    func testContinuationPresetStartsDisabledAndRequiresExistingConversation() throws {
        let preset = ScheduledJob.makeQuotaContinuationPreset()
        XCTAssertEqual(preset.status, .paused)
        XCTAssertFalse(preset.isEnabled)
        XCTAssertFalse(preset.hasValidDestination)
        XCTAssertNil(preset.scheduledExecutionDate)
        XCTAssertEqual(preset.strategy, .autoOnQuotaReset(safetyDelayMinutes: 1))
        XCTAssertEqual(preset.dispatchMode, .silentAPI)
        XCTAssertEqual(preset.templateKind, .quotaContinuation)
        XCTAssertFalse(preset.prompt.isEmpty)
        let restored = try JSONDecoder().decode(ScheduledJob.self, from: JSONEncoder().encode(preset))
        XCTAssertEqual(restored, preset)
    }

    func testLegacyJobEnablementSurvivesDecodingWithoutTemplateKind() throws {
        for status in [JobStatus.pending, .paused] {
            let job = ScheduledJob(status: status)
            var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(job)) as? [String: Any])
            json.removeValue(forKey: "templateKind")
            let data = try JSONSerialization.data(withJSONObject: json)
            let decoded = try JSONDecoder().decode(ScheduledJob.self, from: data)
            XCTAssertEqual(decoded.status, status)
            XCTAssertEqual(decoded.isEnabled, status != .paused)
            XCTAssertNil(decoded.templateKind)
        }
    }

    func testDisabledJobStaysOffAcrossAddEditDueCheckAndRestart() throws {
        try withIsolatedQueue { queue, url, preferences in
            let job = ScheduledJob(prompt: "Do not dispatch", status: .paused, scheduledExecutionDate: Date().addingTimeInterval(-60))
            queue.addJob(job)
            var edited = try XCTUnwrap(queue.jobs.first(where: { $0.id == job.id }))
            edited.title = "Edited while off"
            queue.updateJob(edited)
            queue.checkAndExecuteDueJobs()
            let saved = try XCTUnwrap(queue.jobs.first(where: { $0.id == job.id }))
            XCTAssertEqual(saved.status, .paused)
            XCTAssertNil(saved.scheduledExecutionDate)
            let reloaded = JobQueueManager(persistenceURL: url, preferences: preferences, startsScheduling: false)
            XCTAssertEqual(reloaded.jobs.first(where: { $0.id == job.id }), saved)
        }
    }

    func testSwitchRecalculatesScheduleAndRetainsMessageSettings() throws {
        try withIsolatedQueue { queue, _, _ in
            let job = ScheduledJob(title: "Switch", prompt: "Keep me", reasoningEffort: .medium, strategy: .delayDuration(seconds: 3600))
            queue.addJob(job)
            XCTAssertTrue(queue.setJobEnabled(id: job.id, enabled: false))
            XCTAssertNil(queue.jobs.first(where: { $0.id == job.id })?.scheduledExecutionDate)
            // A stale persisted due date must still be ignored while the switch is off.
            queue.jobs[0].scheduledExecutionDate = Date().addingTimeInterval(-60)
            queue.checkAndExecuteDueJobs()
            XCTAssertEqual(queue.jobs.first(where: { $0.id == job.id })?.status, .paused)
            let before = Date()
            XCTAssertTrue(queue.setJobEnabled(id: job.id, enabled: true))
            let enabled = try XCTUnwrap(queue.jobs.first(where: { $0.id == job.id }))
            XCTAssertEqual(enabled.status, .pending)
            XCTAssertGreaterThanOrEqual(try XCTUnwrap(enabled.scheduledExecutionDate), before.addingTimeInterval(3600))
            XCTAssertEqual(enabled.prompt, job.prompt)
            XCTAssertEqual(enabled.model, job.model)
            XCTAssertEqual(enabled.reasoningEffort, job.reasoningEffort)
            XCTAssertEqual(enabled.destination, job.destination)
            XCTAssertEqual(enabled.strategy, job.strategy)
            queue.jobs[0].status = .sending
            XCTAssertFalse(queue.setJobEnabled(id: job.id, enabled: false))
            XCTAssertEqual(queue.jobs[0].status, .sending)
        }
    }

    func testContinuationCannotEnableOrDispatchBeforeChoosingConversation() throws {
        try withIsolatedQueue { queue, _, _ in
            var job = ScheduledJob.makeQuotaContinuationPreset()
            queue.jobs = [job]
            XCTAssertFalse(queue.setJobEnabled(id: job.id, enabled: true))
            queue.executeJob(jobId: job.id)
            XCTAssertEqual(queue.jobs[0].status, .paused)
            job.destination.conversationAction = .newSession
            XCTAssertFalse(job.hasValidDestination)
            job.destination.conversationAction = .existing(id: "chosen-session", title: "Task to resume")
            queue.updateJob(job)
            XCTAssertEqual(queue.jobs[0].status, .paused)
            XCTAssertTrue(queue.setJobEnabled(id: job.id, enabled: true))
            XCTAssertTrue(queue.jobs[0].isEnabled)
            XCTAssertEqual(queue.jobs[0].destination, job.destination)
        }
    }

    func testContinuationWaitsForQuotaThenSchedulesWithSafetyBuffer() throws {
        try withIsolatedQueue { queue, _, _ in
            var job = ScheduledJob.makeQuotaContinuationPreset()
            job.destination.conversationAction = .existing(id: "chosen-session", title: "Task")
            job.status = .pending
            let unknown = QuotaSnapshot(usedPercent: 0, resetsAt: nil, windowMinutes: 300)
            let waiting = queue.preparedForScheduling(job, currentQuota: unknown)
            XCTAssertEqual(waiting.status, .waitingForQuota)
            XCTAssertNil(waiting.scheduledExecutionDate)
            queue.jobs = [waiting, ScheduledJob.makeQuotaContinuationPreset()]
            queue.checkAndExecuteDueJobs()
            XCTAssertEqual(queue.jobs[0].status, .waitingForQuota)
            let reset = Date().addingTimeInterval(3600)
            queue.scheduleWaitingContinuations(currentQuota: QuotaSnapshot(usedPercent: 100, resetsAt: reset, windowMinutes: 300))
            XCTAssertEqual(queue.jobs[0].status, .pending)
            XCTAssertEqual(try XCTUnwrap(queue.jobs[0].scheduledExecutionDate).timeIntervalSince(reset), 60, accuracy: 0.01)
            XCTAssertEqual(queue.jobs[1].status, .paused)
            XCTAssertNil(queue.jobs[1].scheduledExecutionDate)
        }
    }

    func testContinuationStarterInstalledOnceWithoutReplacingOrRestoringDeletedJobs() throws {
        let original = ScheduledJob(title: "User's existing job", prompt: "Preserve", strategy: .customTime(Date().addingTimeInterval(7200)), scheduledExecutionDate: Date().addingTimeInterval(7200))
        try withIsolatedQueue(initialJobs: [original]) { queue, url, preferences in
            XCTAssertEqual(queue.jobs.filter { $0.templateKind == .quotaContinuation }.count, 1)
            let existing = try XCTUnwrap(queue.jobs.first(where: { $0.templateKind == nil }))
            XCTAssertEqual(existing, original)
            let restored = JobQueueManager(persistenceURL: url, preferences: preferences, startsScheduling: false)
            XCTAssertEqual(restored.jobs.count, 2)
            XCTAssertEqual(restored.jobs.first(where: { $0.id == existing.id }), existing)
            let preset = try XCTUnwrap(restored.jobs.first(where: { $0.templateKind == .quotaContinuation }))
            restored.deleteJob(id: preset.id)
            let afterDelete = JobQueueManager(persistenceURL: url, preferences: preferences, startsScheduling: false)
            XCTAssertEqual(afterDelete.jobs.map(\.id), [existing.id])
            afterDelete.deleteJob(id: existing.id)
            let empty = JobQueueManager(persistenceURL: url, preferences: preferences, startsScheduling: false)
            XCTAssertTrue(empty.jobs.isEmpty)
        }
    }

    @MainActor
    func testMenuKeepsDistinctSessionsWithDuplicateTitles() {
        let titles = ["Morning", "Review", "Morning", "Review", "Release"]
        let control = NSPopUpButton(frame: .zero, pullsDown: false)
        control.menu = Next5hMenuPicker<String>.makeMenu(titles: titles)

        XCTAssertEqual(control.itemTitles, titles)
        control.selectItem(at: 3)
        XCTAssertEqual(control.indexOfSelectedItem, 3)
        XCTAssertEqual(control.titleOfSelectedItem, "Review")
    }

    func testHistoryTemplateStrategyPersistence() throws {
        let strategies: [ScheduleStrategy] = [
            .dailyAtTime(hour: 9, minute: 25),
            .autoOnQuotaReset(safetyDelayMinutes: 4),
            .delayDuration(seconds: 10800),
            .customTime(Date(timeIntervalSince1970: 1800000000))
        ]
        for strategy in strategies {
            let record = DispatchHistoryRecord(title: "Template", prompt: "Review", strategy: strategy)
            let decoded = try JSONDecoder().decode(DispatchHistoryRecord.self, from: JSONEncoder().encode(record))
            XCTAssertEqual(decoded.templateStrategy(sourceJob: nil), strategy)
            XCTAssertEqual(decoded.templateStrategy(sourceJob: ScheduledJob()), strategy)
        }
    }

    func testLegacyHistoryTemplateStrategyFallback() throws {
        let record = DispatchHistoryRecord(title: "Legacy", prompt: "Review")
        let data = try JSONEncoder().encode(record)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        json.removeValue(forKey: "strategy")
        let legacyData = try JSONSerialization.data(withJSONObject: json)
        let decoded = try JSONDecoder().decode(DispatchHistoryRecord.self, from: legacyData)
        XCTAssertNil(decoded.strategy)
        let source = ScheduledJob(strategy: .delayDuration(seconds: 7200))
        XCTAssertEqual(decoded.templateStrategy(sourceJob: source), source.strategy)
        XCTAssertEqual(decoded.templateStrategy(sourceJob: nil), .dailyAtTime(hour: 7, minute: 0))
    }


    func testDynamicModelCatalogLoading() {
        let models = ModelCatalogService.loadFromDisk()
        XCTAssertFalse(models.isEmpty)

        let sol = models.first(where: { $0.slug == "gpt-5.6-sol" })
        XCTAssertNotNil(sol)
        XCTAssertEqual(sol?.displayName, "5.6 Sol")
        XCTAssertEqual(sol?.supportedReasoningLevels.count, 6)
        XCTAssertTrue(sol?.supportsSpeedSelection ?? false)
        
        let luna = models.first(where: { $0.slug == "gpt-5.6-luna" })
        XCTAssertNotNil(luna)
        XCTAssertEqual(luna?.displayName, "5.6 Luna")
        XCTAssertTrue(luna?.supportsSpeedSelection ?? false)
    }
    
    func testModelCatalogAutoResolutionOnDeprecation() {
        let service = ModelCatalogService.shared
        let nonexistent = service.resolveModel(slugOrName: "gpt-3.5-turbo-obsolete")
        XCTAssertEqual(nonexistent.slug, service.defaultModel.slug)
    }
    
    func testTargetDestinationHierarchy() {
        let dest = TargetDestination(
            projectScope: .specific(id: "p1", name: "Project-A"),
            conversationAction: .newSession
        )
        XCTAssertEqual(dest.summary, "Project-A → 新建会话")
        
        let globalDest = TargetDestination(
            projectScope: .noProject,
            conversationAction: .existing(id: "s1", title: "历史会话-1")
        )
        XCTAssertEqual(globalDest.summary, "无项目 (常规对话) → 历史会话-1")
    }
    
    func testSmartSchedulerSafetyDelayBuffer() {
        let resetDate = Date().addingTimeInterval(3600) // 1 hour from now
        let quota = QuotaSnapshot(usedPercent: 100, resetsAt: resetDate, windowMinutes: 300)
        
        let strategy = ScheduleStrategy.autoOnQuotaReset(safetyDelayMinutes: 1)
        let scheduledDate = SmartScheduler.shared.calculateNextExecutionDate(for: strategy, currentQuota: quota)
        
        let diff = scheduledDate.timeIntervalSince(resetDate)
        XCTAssertEqual(diff, 60, accuracy: 1.0)
    }
    
    func testDefaultPresetJobUpdated() {
        let defaultJob = ScheduledJob.makeDefaultPreset()
        XCTAssertEqual(defaultJob.prompt, "嗨")
        XCTAssertEqual(defaultJob.model.slug, "gpt-6-luna")
        XCTAssertEqual(defaultJob.model.displayName, "6 Luna")
        XCTAssertEqual(defaultJob.reasoningEffort, .low)
        XCTAssertEqual(defaultJob.speed, .standard)
        XCTAssertEqual(defaultJob.destination.projectScope, .noProject)
        XCTAssertTrue(defaultJob.isDefaultPreset)
        
        if case .dailyAtTime(let h, let m) = defaultJob.strategy {
            XCTAssertEqual(h, 7)
            XCTAssertEqual(m, 0)
        } else {
            XCTFail("Strategy should be daily at 7:00")
        }
    }
    
    func testQuotaSnapshotLockedState() {
        let future = Date().addingTimeInterval(3665) // 1h 1m 5s
        let lockedQuota = QuotaSnapshot(
            usedPercent: 100,
            resetsAt: future,
            windowMinutes: 300,
            weeklyUsedPercent: 50,
            weeklyResetsAt: Date().addingTimeInterval(86400 * 3 + 3600 * 2) // 3d 2h
        )
        XCTAssertTrue(lockedQuota.isLocked)
        XCTAssertGreaterThan(lockedQuota.remainingSeconds, 0)
        
        let normalQuota = QuotaSnapshot(usedPercent: 40, resetsAt: future, windowMinutes: 300)
        XCTAssertFalse(normalQuota.isLocked)
        
        // 验证中英文及日文倒计时与单位
        LocalizationManager.shared.setLanguage(.zh)
        XCTAssertTrue(lockedQuota.formattedRemainingTime.contains("小时") && lockedQuota.formattedRemainingTime.contains("分"))
        XCTAssertTrue(lockedQuota.formattedWeeklyRemainingTime.contains("天") && lockedQuota.formattedWeeklyRemainingTime.contains("小时"))
        
        LocalizationManager.shared.setLanguage(.en)
        XCTAssertTrue(lockedQuota.formattedRemainingTime.contains("h") && lockedQuota.formattedRemainingTime.contains("m"))
        XCTAssertTrue(lockedQuota.formattedWeeklyRemainingTime.contains("d") && lockedQuota.formattedWeeklyRemainingTime.contains("h"))
        
        LocalizationManager.shared.setLanguage(.ja)
        XCTAssertTrue(lockedQuota.formattedRemainingTime.contains("時間") && lockedQuota.formattedRemainingTime.contains("分"))
        XCTAssertTrue(lockedQuota.formattedWeeklyRemainingTime.contains("日") && lockedQuota.formattedWeeklyRemainingTime.contains("時間"))
        
        // 验证 ProbeLogEntry 自适应
        let entry = ProbeLogEntry(timestamp: Date(), zh: "测试中文日志", en: "Test English log", ja: "テスト日本語ログ")
        XCTAssertTrue(entry.formattedMessage(lang: .zh).contains("测试中文日志"))
        XCTAssertTrue(entry.formattedMessage(lang: .en).contains("Test English log"))
        XCTAssertTrue(entry.formattedMessage(lang: .ja).contains("テスト日本語ログ"))
        
        // 恢复中文
        LocalizationManager.shared.setLanguage(.zh)
    }
    
    func testDispatchHistoryRecordModel() {
        let record = DispatchHistoryRecord(
            title: "每日打卡",
            prompt: "嗨",
            dispatchedAt: Date(),
            durationSeconds: 1.25,
            isSuccess: true,
            modelSlug: "gpt-5.6-luna",
            modelDisplayName: "5.6 Luna",
            reasoningEffort: "低",
            speed: "标准",
            destinationSummary: "新建会话",
            targetSessionId: "session-abc-123",
            dispatchMode: .silentAPI,
            triggerStrategySummary: "每天 07:00 准时触发"
        )
        
        XCTAssertEqual(record.title, "每日打卡")
        XCTAssertTrue(record.isSuccess)
        XCTAssertEqual(record.durationSeconds, 1.25)
        XCTAssertEqual(record.targetSessionId, "session-abc-123")
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        guard let data = try? encoder.encode(record),
              let decoded = try? decoder.decode(DispatchHistoryRecord.self, from: data) else {
            XCTFail("Failed to encode/decode DispatchHistoryRecord")
            return
        }
        XCTAssertEqual(decoded.id, record.id)
        XCTAssertEqual(decoded.title, record.title)
    }
    
    func testDispatchHistoryManagerOperations() {
        let manager = DispatchHistoryManager.shared
        let initialCount = manager.records.count
        
        let record = DispatchHistoryRecord(
            title: "单元测试任务",
            prompt: "Test prompt",
            isSuccess: true,
            modelDisplayName: "5.6 Sol",
            reasoningEffort: "高",
            destinationSummary: "测试项目"
        )
        
        manager.addRecord(record)
        XCTAssertEqual(manager.records.first?.id, record.id)
        XCTAssertEqual(manager.records.count, initialCount + 1)
        
        manager.deleteRecord(id: record.id)
        XCTAssertEqual(manager.records.count, initialCount)
    }
    
    func testJobQueueManagerLifecycle() throws {
        try withIsolatedQueue { queue, _, _ in

            let testJob = ScheduledJob(
                id: UUID(),
                title: "生命周期测试任务",
                prompt: "echo test",
                strategy: .dailyAtTime(hour: 7, minute: 0),
                dispatchMode: .silentAPI
            )

            // 1. 测试添加
            queue.addJob(testJob)
            XCTAssertTrue(queue.jobs.contains(where: { $0.id == testJob.id }))

            // 2. 测试暂停与恢复
            queue.togglePause(id: testJob.id)
            if let found = queue.jobs.first(where: { $0.id == testJob.id }) {
                XCTAssertEqual(found.status, .paused)
            } else {
                XCTFail("Job not found")
            }

            queue.togglePause(id: testJob.id)
            if let found = queue.jobs.first(where: { $0.id == testJob.id }) {
                XCTAssertEqual(found.status, .pending)
                XCTAssertNotNil(found.scheduledExecutionDate)
            }

            // 3. 测试更新
            var modified = testJob
            modified.title = "已修改的测试任务"
            queue.updateJob(modified)
            if let found = queue.jobs.first(where: { $0.id == testJob.id }) {
                XCTAssertEqual(found.title, "已修改的测试任务")
            }

            // 4. 测试删除
            queue.deleteJob(id: testJob.id)
            XCTAssertFalse(queue.jobs.contains(where: { $0.id == testJob.id }))

        }
    }
    
    func testAppStateNavigationIntegrity() {
        let tabs = NavigationTab.allCases
        XCTAssertEqual(tabs.count, 3)
        XCTAssertEqual(tabs[0], .queue)
        XCTAssertEqual(tabs[1], .history)
        XCTAssertEqual(tabs[2], .dashboard)
        
        // 测试中文模式
        LocalizationManager.shared.setLanguage(.zh)
        XCTAssertEqual(NavigationTab.queue.title, "待发消息")
        XCTAssertEqual(NavigationTab.history.title, "消息历史")
        XCTAssertEqual(NavigationTab.dashboard.title, "额度看板")
        
        // 测试英文模式
        LocalizationManager.shared.setLanguage(.en)
        XCTAssertEqual(NavigationTab.queue.title, "Pending")
        XCTAssertEqual(NavigationTab.history.title, "History")
        XCTAssertEqual(NavigationTab.dashboard.title, "Quota")
        
        // 恢复默认中文测试环境
        LocalizationManager.shared.setLanguage(.zh)
        
        let appState = AppState.shared
        XCTAssertEqual(appState.selectedTab, .queue)
        
        // 测试 Sheet 弹窗控制
        appState.openNewJobSheet()
        XCTAssertTrue(appState.isShowingJobSheet)
        XCTAssertNil(appState.editingJob)
        
        let testJob = ScheduledJob.makeDefaultPreset()
        appState.openEditJobSheet(job: testJob)
        XCTAssertTrue(appState.isShowingJobSheet)
        XCTAssertEqual(appState.editingJob?.id, testJob.id)
        
        appState.closeJobSheet()
        XCTAssertFalse(appState.isShowingJobSheet)
        XCTAssertNil(appState.editingJob)
    }
    
    func testLocalizationManagerLanguageSwitching() {
        let loc = LocalizationManager.shared
        
        loc.setLanguage(.en)
        XCTAssertEqual(loc.currentLanguage, .en)
        XCTAssertEqual(L10n.tabPending, "Pending")
        XCTAssertEqual(L10n.tabHistory, "History")
        XCTAssertEqual(L10n.tabDashboard, "Quota")
        XCTAssertEqual(L10n.menuQuit, "Quit Next5h")
        XCTAssertEqual(L10n.queueNewMessage, "New Message")
        XCTAssertEqual(DispatchMode.silentAPI.displayName, "Silent Background (Recommended)")
        XCTAssertEqual(ReasoningEffort.low.displayName, "Low")
        XCTAssertEqual(SpeedPreference.standard.displayName, "Standard")
        XCTAssertEqual(ProjectScope.noProject.displayName, "No Project (General)")
        XCTAssertEqual(ConversationAction.newSession.displayName, "New Session")
        
        loc.setLanguage(.ja)
        XCTAssertEqual(loc.currentLanguage, .ja)
        XCTAssertEqual(L10n.tabPending, "送信待ち")
        XCTAssertEqual(L10n.tabHistory, "送信履歴")
        XCTAssertEqual(L10n.tabDashboard, "クォータ監視")
        XCTAssertEqual(L10n.menuQuit, "Next5h を終了")
        XCTAssertEqual(L10n.queueNewMessage, "新規メッセージ")
        XCTAssertEqual(DispatchMode.silentAPI.displayName, "バックグラウンドサイレント送信 (推奨)")
        XCTAssertEqual(ReasoningEffort.low.displayName, "低")
        XCTAssertEqual(SpeedPreference.standard.displayName, "標準")
        XCTAssertEqual(ProjectScope.noProject.displayName, "プロジェクトなし (通常会話)")
        XCTAssertEqual(ConversationAction.newSession.displayName, "新規セッション")
        
        // 测试多语拓展机制 (L10n.tr) 及回退机制 (Fallback)
        let multiTest1 = L10n.tr(zh: "你好", en: "Hello", ja: "こんにちは", fr: "Bonjour")
        XCTAssertEqual(multiTest1, "こんにちは")
        
        // 若缺少当前语言，回退到英语
        let fallbackTest = L10n.tr(zh: "你好", en: "Hello")
        XCTAssertEqual(fallbackTest, "Hello")
        
        loc.setLanguage(.zh)
        XCTAssertEqual(loc.currentLanguage, .zh)
        XCTAssertEqual(L10n.tabPending, "待发消息")
        XCTAssertEqual(L10n.tabHistory, "消息历史")
        XCTAssertEqual(L10n.tabDashboard, "额度看板")
        XCTAssertEqual(L10n.menuQuit, "退出 Next5h")
        XCTAssertEqual(L10n.queueNewMessage, "新建消息")
        XCTAssertEqual(DispatchMode.silentAPI.displayName, "静默后台发送 (推荐)")
        XCTAssertEqual(ReasoningEffort.low.displayName, "轻度")
        XCTAssertEqual(SpeedPreference.standard.displayName, "标准")
        XCTAssertEqual(ProjectScope.noProject.displayName, "无项目 (常规对话)")
        XCTAssertEqual(ConversationAction.newSession.displayName, "新建会话")
    }
    
    func testStatusItemRendererMonochromeDualCylinder() {
        let normalImg = StatusItemRenderer.renderDualCylinder(remaining5h: 60.0, remainingWeekly: 93.0, isLocked: false)
        XCTAssertEqual(normalImg.size.width, 28.0)
        XCTAssertEqual(normalImg.size.height, 22.0)
        XCTAssertTrue(normalImg.isTemplate)
        
        let lockedImg = StatusItemRenderer.renderDualCylinder(remaining5h: 0.0, remainingWeekly: 0.0, isLocked: true)
        XCTAssertEqual(lockedImg.size.width, 28.0)
        XCTAssertEqual(lockedImg.size.height, 22.0)
        XCTAssertTrue(lockedImg.isTemplate)
    }
    
    func testStandbyPowerAssertionLifecycle() {
        let guardian = PowerGuardian.shared
        
        // 1. 模拟有待发任务：应当激活待命防休眠断言
        guardian.updateStandbyAssertion(hasPendingJobs: true)
        XCTAssertTrue(guardian.isStandbyAssertionActive)
        
        // 2. 模拟任务全部完成，队列无待发任务：应当自动释放断言以节省电量
        guardian.updateStandbyAssertion(hasPendingJobs: false)
        XCTAssertFalse(guardian.isStandbyAssertionActive)
    }
    
    func testCodexBinaryPathResolution() {
        let path = SilentAPIDispatcher.resolveCodexBinaryPath()
        XCTAssertNotNil(path, "应当成功解析到本地可执行的 Codex CLI 路径")
        if let p = path {
            XCTAssertTrue(FileManager.default.isExecutableFile(atPath: p), "解析得到的路径应当具备可执行权限: \(p)")
        }
    }
    
    func testCodexCLIExecutableInvocation() {
        guard let path = SilentAPIDispatcher.resolveCodexBinaryPath() else {
            XCTFail("应当成功获取 Codex CLI 路径")
            return
        }
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: path)
        proc.arguments = ["--version"]
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = pipe
        XCTAssertNoThrow(try proc.run(), "调用解析出的 Codex CLI 不应再抛出 Cocoa Error 260")
        proc.waitUntilExit()
        XCTAssertEqual(proc.terminationStatus, 0)
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let out = String(data: data, encoding: .utf8) ?? ""
        XCTAssertTrue(out.contains("codex-cli"), "输出应包含 codex-cli 版本信息")
    }
    
    func testDailyJobAutoRescheduleOnFailure() throws {
        try withIsolatedQueue { qm, url, preferences in

            let dailyJob = ScheduledJob(
                id: UUID(),
                title: "单元测试每日任务",
                prompt: "ping",
                model: ModelCatalogService.shared.defaultModel,
                reasoningEffort: .low,
                speed: .standard,
                destination: TargetDestination(),
                strategy: .dailyAtTime(hour: 6, minute: 40),
                dispatchMode: .silentAPI,
                status: .failed("模拟的测试失败"),
                createdAt: Date(),
                scheduledExecutionDate: Date().addingTimeInterval(-3600) // 过去的时间
            )

            qm.jobs.append(dailyJob)

            // 模拟触发保存与加载自愈
            qm.saveJobs()

            let reloaded = JobQueueManager(persistenceURL: url, preferences: preferences, startsScheduling: false)
            let rescheduled = try XCTUnwrap(reloaded.jobs.first(where: { $0.id == dailyJob.id }))
            XCTAssertEqual(rescheduled.status, .pending)
            XCTAssertGreaterThan(try XCTUnwrap(rescheduled.scheduledExecutionDate), Date())
        }
    }
    
    func testCodexSessionWatcherActivityDetection() {
        let watcher = CodexSessionWatcher.shared
        let snapshot = watcher.queryActivitySnapshot()
        
        // 验证能正常查询本地 thread_history_1.sqlite
        XCTAssertGreaterThanOrEqual(snapshot.latestStartedAt, 0)
        XCTAssertGreaterThanOrEqual(snapshot.latestCompletedAt, 0)
        
        // 验证建议间隔：若处于活跃窗口返回 60s，否则返回 <= 300s
        let interval = watcher.currentRecommendedInterval
        XCTAssertTrue(interval == 60 || interval == 180 || interval == 300, "建议轮询间隔应为 60s、180s 或 300s，当前为: \(interval)")
    }
}

