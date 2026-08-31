import Foundation

public struct DispatchHistoryRecord: Identifiable, Codable, Equatable {
    public var id: UUID
    public var jobId: UUID?
    public var title: String
    public var prompt: String
    public var dispatchedAt: Date
    public var durationSeconds: Double
    public var isSuccess: Bool
    public var errorMessage: String?
    public var modelSlug: String
    public var modelDisplayName: String
    public var reasoningEffort: String
    public var speed: String
    public var destinationSummary: String
    public var targetSessionId: String?
    public var dispatchMode: DispatchMode
    public var triggerStrategySummary: String
    
    public init(
        id: UUID = UUID(),
        jobId: UUID? = nil,
        title: String,
        prompt: String,
        dispatchedAt: Date = Date(),
        durationSeconds: Double = 0.0,
        isSuccess: Bool = true,
        errorMessage: String? = nil,
        modelSlug: String = "gpt-5.6-luna",
        modelDisplayName: String = "5.6 Luna",
        reasoningEffort: String = "低",
        speed: String = "标准",
        destinationSummary: String = "新建会话",
        targetSessionId: String? = nil,
        dispatchMode: DispatchMode = .silentAPI,
        triggerStrategySummary: String = "手动/定时派发"
    ) {
        self.id = id
        self.jobId = jobId
        self.title = title
        self.prompt = prompt
        self.dispatchedAt = dispatchedAt
        self.durationSeconds = durationSeconds
        self.isSuccess = isSuccess
        self.errorMessage = errorMessage
        self.modelSlug = modelSlug
        self.modelDisplayName = modelDisplayName
        self.reasoningEffort = reasoningEffort
        self.speed = speed
        self.destinationSummary = destinationSummary
        self.targetSessionId = targetSessionId
        self.dispatchMode = dispatchMode
        self.triggerStrategySummary = triggerStrategySummary
    }
}
