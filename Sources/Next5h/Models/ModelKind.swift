import Foundation

public enum ReasoningEffort: String, Codable, CaseIterable, Identifiable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case xhigh = "xhigh"
    case max = "max"
    case ultra = "ultra"
    
    public var id: String { rawValue }
    
    /// 100% 对齐官方客户端本地化文案
    public var displayName: String {
        let isZh = LocalizationManager.shared.currentLanguage == .zh
        switch self {
        case .low: return isZh ? "轻度" : "Low"
        case .medium: return isZh ? "中" : "Medium"
        case .high: return isZh ? "高" : "High"
        case .xhigh: return isZh ? "极高" : "Extra High"
        case .max: return "Max"
        case .ultra: return "Ultra"
        }
    }
    
    public var shortLabel: String {
        return displayName
    }
    
    public static func fromEffortString(_ str: String) -> ReasoningEffort {
        switch str.lowercased() {
        case "low", "minimal", "none": return .low
        case "medium": return .medium
        case "high": return .high
        case "xhigh": return .xhigh
        case "max": return .max
        case "ultra": return .ultra
        default: return .medium
        }
    }
}

public enum SpeedPreference: String, Codable, CaseIterable, Identifiable {
    case standard = "标准"
    case fast = "快速"
    
    public var id: String { rawValue }
    public var displayName: String {
        let isZh = LocalizationManager.shared.currentLanguage == .zh
        switch self {
        case .standard: return isZh ? "标准" : "Standard"
        case .fast: return isZh ? "快速" : "Fast"
        }
    }
}

public struct DynamicCodexModel: Identifiable, Codable, Equatable, Hashable {
    public var id: String { slug }
    public var slug: String
    public var displayName: String
    public var description: String
    public var supportedReasoningLevels: [ReasoningEffort]
    public var defaultReasoningLevel: ReasoningEffort
    public var supportsSpeedSelection: Bool
    public var isFlagship: Bool
    
    public init(
        slug: String,
        displayName: String,
        description: String = "",
        supportedReasoningLevels: [ReasoningEffort] = [.low, .medium, .high],
        defaultReasoningLevel: ReasoningEffort = .medium,
        supportsSpeedSelection: Bool = true,
        isFlagship: Bool = false
    ) {
        self.slug = slug
        self.displayName = displayName
        self.description = description
        self.supportedReasoningLevels = supportedReasoningLevels
        self.defaultReasoningLevel = defaultReasoningLevel
        self.supportsSpeedSelection = supportsSpeedSelection
        self.isFlagship = isFlagship
    }
    
    public static func fallbackDefault() -> DynamicCodexModel {
        return DynamicCodexModel(
            slug: "gpt-5.6-sol",
            displayName: "5.6 Sol",
            description: "默认旗舰模型",
            supportedReasoningLevels: [.low, .medium, .high, .xhigh, .max, .ultra],
            defaultReasoningLevel: .medium,
            supportsSpeedSelection: true,
            isFlagship: true
        )
    }
}
