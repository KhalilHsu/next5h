import Foundation

public enum ProjectScope: Codable, Equatable, Hashable {
    case noProject
    case specific(id: String, name: String)
    
    public var isSpecific: Bool {
        if case .specific = self { return true }
        return false
    }
    
    public var displayName: String {
        switch self {
        case .noProject: return "无项目 (常规对话)"
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
        switch self {
        case .newSession: return "新建会话"
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
