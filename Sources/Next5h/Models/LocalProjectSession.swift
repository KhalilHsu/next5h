import Foundation

public struct CodexSession: Identifiable, Codable, Equatable, Hashable {
    public var id: String
    public var title: String
    public var updatedAt: Date
    public var projectId: String?
    public var isLocalDetected: Bool
    
    public init(id: String, title: String, updatedAt: Date = Date(), projectId: String? = nil, isLocalDetected: Bool = true) {
        self.id = id
        self.title = title
        self.updatedAt = updatedAt
        self.projectId = projectId
        self.isLocalDetected = isLocalDetected
    }
}

public struct CodexProject: Identifiable, Codable, Equatable, Hashable {
    public var id: String
    public var name: String
    public var description: String
    public var sessions: [CodexSession]
    
    public init(id: String, name: String, description: String = "", sessions: [CodexSession] = []) {
        self.id = id
        self.name = name
        self.description = description
        self.sessions = sessions
    }
}
