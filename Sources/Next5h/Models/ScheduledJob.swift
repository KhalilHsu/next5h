import Foundation

public enum JobStatus: Codable, Equatable {
    case pending
    case waitingForQuota
    case sending
    case completed(Date)
    case failed(String)
    case paused
    
    public var statusName: String {
        switch self {
        case .pending: return "待触发"
        case .waitingForQuota: return "等待 5H 额度解封"
        case .sending: return "发送中..."
        case .completed: return "已完成"
        case .failed(let err): return "失败: \(err)"
        case .paused: return "已暂停"
        }
    }
    
    public var iconName: String {
        switch self {
        case .pending: return "clock.fill"
        case .waitingForQuota: return "hourglass"
        case .sending: return "paperplane.fill"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        case .paused: return "pause.circle.fill"
        }
    }
}

public struct ScheduledJob: Identifiable, Codable, Equatable {
    public var id: UUID
    public var title: String
    public var prompt: String
    public var model: DynamicCodexModel
    public var reasoningEffort: ReasoningEffort
    public var speed: SpeedPreference
    public var destination: TargetDestination
    public var strategy: ScheduleStrategy
    public var dispatchMode: DispatchMode
    public var status: JobStatus
    public var createdAt: Date
    public var scheduledExecutionDate: Date?
    public var executedAt: Date?
    public var lastErrorMessage: String?
    public var isDefaultPreset: Bool
    
    public init(
        id: UUID = UUID(),
        title: String = "未命名任务",
        prompt: String = "",
        model: DynamicCodexModel = DynamicCodexModel.fallbackDefault(),
        reasoningEffort: ReasoningEffort = .low,
        speed: SpeedPreference = .standard,
        destination: TargetDestination = TargetDestination(),
        strategy: ScheduleStrategy = .dailyAtTime(hour: 7, minute: 0),
        dispatchMode: DispatchMode = .silentAPI,
        status: JobStatus = .pending,
        createdAt: Date = Date(),
        scheduledExecutionDate: Date? = nil,
        executedAt: Date? = nil,
        lastErrorMessage: String? = nil,
        isDefaultPreset: Bool = false
    ) {
        self.id = id
        self.title = title
        self.prompt = prompt
        self.model = model
        self.reasoningEffort = reasoningEffort
        self.speed = speed
        self.destination = destination
        self.strategy = strategy
        self.dispatchMode = dispatchMode
        self.status = status
        self.createdAt = createdAt
        self.scheduledExecutionDate = scheduledExecutionDate
        self.executedAt = executedAt
        self.lastErrorMessage = lastErrorMessage
        self.isDefaultPreset = isDefaultPreset
    }
    
    /// 默认初始任务预置 (精确预定明天 07:00, 5.6 Luna, 推理强度: 低, 速度: 标准, "嗨")
    public static func makeDefaultPreset() -> ScheduledJob {
        let lunaModel = ModelCatalogService.shared.resolveModel(slugOrName: "gpt-5.6-luna")
        let strategy = ScheduleStrategy.dailyAtTime(hour: 7, minute: 0)
        let firstExecutionDate = SmartScheduler.shared.calculateNextExecutionDate(
            for: strategy,
            currentQuota: QuotaProbeEngine.shared.currentQuota
        )
        
        return ScheduledJob(
            id: UUID(),
            title: "🌅 每日 07:00 初始问候与激活",
            prompt: "嗨",
            model: lunaModel,
            reasoningEffort: .low,
            speed: .standard,
            destination: TargetDestination(projectScope: .noProject, conversationAction: .newSession),
            strategy: strategy,
            dispatchMode: .silentAPI,
            status: .pending,
            createdAt: Date(),
            scheduledExecutionDate: firstExecutionDate,
            isDefaultPreset: true
        )
    }
}
