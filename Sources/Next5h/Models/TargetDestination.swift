import Foundation

public enum ProjectScope: Codable, Equatable, Hashable {
    case noProject
    case specific(id: String, name: String)
    
    public var isSpecific: Bool {
        if case .specific = self { return true }
        return false
    }
    
    public var displayName: String {
        let isZh = LocalizationManager.shared.currentLanguage == .zh
        switch self {
        case .noProject: return isZh ? "无项目 (常规对话)" : "No Project (General)"
        case .specific(_, let name): return name
        }
    }
}

public enum ConversationAction: Codable, Equatable, Hashable {
    case newSession
    case existing(id: String, title: String)
    
    public var isNew: Bool {
        if case .newSession = self { return true }
        return false
    }
    
    public var displayName: String {
        let isZh = LocalizationManager.shared.currentLanguage == .zh
        switch self {
        case .newSession: return isZh ? "新建会话" : "New Session"
        case .existing(_, let title): return title
        }
    }
}

public struct TargetDestination: Codable, Equatable, Hashable {
    public var projectScope: ProjectScope
    public var conversationAction: ConversationAction
    
    public init(projectScope: ProjectScope = .noProject, conversationAction: ConversationAction = .newSession) {
        self.projectScope = projectScope
        self.conversationAction = conversationAction
    }
    
    public var summary: String {
        let proj = projectScope.displayName
        let conv = conversationAction.displayName
        return "\(proj) → \(conv)"
    }
}
