import XCTest
@testable import Next5h

final class Next5hTests: XCTestCase {
    
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
        XCTAssertEqual(defaultJob.model.slug, "gpt-5.6-luna")
        XCTAssertEqual(defaultJob.model.displayName, "5.6 Luna")
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
        let future = Date().addingTimeInterval(1800)
        let lockedQuota = QuotaSnapshot(usedPercent: 100, resetsAt: future, windowMinutes: 300)
        XCTAssertTrue(lockedQuota.isLocked)
        XCTAssertGreaterThan(lockedQuota.remainingSeconds, 0)
        
        let normalQuota = QuotaSnapshot(usedPercent: 40, resetsAt: future, windowMinutes: 300)
        XCTAssertFalse(normalQuota.isLocked)
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
    
    func testJobQueueManagerLifecycle() {
        let queue = JobQueueManager.shared
        let originalJobs = queue.jobs
        
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
        
        // 恢复原始队列
        queue.jobs = originalJobs
        queue.saveJobs()
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
}

