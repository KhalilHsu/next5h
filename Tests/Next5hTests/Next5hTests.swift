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
}
