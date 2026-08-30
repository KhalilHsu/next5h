import Foundation

public final class SessionRouter: ObservableObject {
    public static let shared = SessionRouter()
    
    @Published public var realCodexProjects: [CodexProject] = []
    @Published public var noProjectSessions: [CodexSession] = []
    
    private init() {
        reloadData()
    }
    
    public func reloadData() {
        let (projects, noProj) = LocalCodexContextReader.shared.fetchCategorizedProjectsAndSessions()
        self.realCodexProjects = projects
        self.noProjectSessions = noProj
        
        print("✅ [SessionRouter] 已从本地 state_5.sqlite 严格分类完成:")
        print("   - 无项目独立会话: \(noProjectSessions.count) 条: \(noProjectSessions.map { $0.title }.joined(separator: ", "))")
        for p in realCodexProjects {
            print("   - 项目 [\(p.name)]: \(p.sessions.count) 条会话: \(p.sessions.map { $0.title }.joined(separator: ", "))")
        }
    }
    
    /// 严格按选定范围返回过滤后的会话列表
    public func sessions(for projectScope: ProjectScope) -> [CodexSession] {
        switch projectScope {
        case .noProject:
            // 严格只返回无项目的会话
            return noProjectSessions
        case .specific(let id, _):
            // 严格只返回该项目内的会话
            return realCodexProjects.first(where: { $0.id == id })?.sessions ?? []
        }
    }
}
