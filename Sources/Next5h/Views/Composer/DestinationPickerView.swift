import SwiftUI

public struct DestinationPickerView: View {
    @Binding public var destination: TargetDestination
    @ObservedObject private var sessionRouter = SessionRouter.shared
    @ObservedObject private var loc = LocalizationManager.shared
    
    @State private var isSpecificProject: Bool = false
    @State private var selectedProjectId: String = ""
    @State private var isNewSession: Bool = true
    @State private var selectedSessionId: String = ""
    
    public init(destination: Binding<TargetDestination>) {
        self._destination = destination
        let initial = destination.wrappedValue
        let router = SessionRouter.shared
        let projectID: String
        if case .specific(let id, _) = initial.projectScope {
            projectID = id
        } else {
            projectID = router.realCodexProjects.first?.id ?? ""
        }
        let sessionID: String
        if case .existing(let id, _) = initial.conversationAction {
            sessionID = id
        } else {
            sessionID = router.sessions(for: initial.projectScope).first?.id ?? ""
        }
        // Initialize state without firing scope/project change handlers and selecting a different session.
        self._isSpecificProject = State(initialValue: initial.projectScope.isSpecific)
        self._selectedProjectId = State(initialValue: projectID)
        self._isNewSession = State(initialValue: initial.conversationAction.isNew)
        self._selectedSessionId = State(initialValue: sessionID)
    }
    
    /// 当前选定范围下的会话列表
    private var availableSessions: [CodexSession] {
        if isSpecificProject {
            return sessionRouter.realCodexProjects.first(where: { $0.id == selectedProjectId })?.sessions ?? []
        } else {
            return sessionRouter.noProjectSessions
        }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Next5hSectionHeading(title: L10n.tr(zh: "发送到", en: "Destination", ja: "送信先"), symbol: "arrow.triangle.branch")

            // 第一步：选择项目归属
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.tr(zh: "归属范围", en: "Scope", ja: "所属スコープ"))
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                
                Next5hSegmentedControl(
                    label: L10n.tr(zh: "归属范围", en: "Scope", ja: "所属スコープ"),
                    selection: $isSpecificProject,
                    options: [
                        .init(value: false, title: L10n.tr(zh: "无项目", en: "No project", ja: "プロジェクトなし")),
                        .init(value: true, title: L10n.tr(zh: "本地项目", en: "Local project", ja: "ローカル"))
                    ]
                )

                if isSpecificProject {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.tr(zh: "所属项目", en: "Project", ja: "対象プロジェクト"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Next5hMenuPicker(
                            label: L10n.tr(zh: "选择项目", en: "Choose project", ja: "プロジェクトを選択"),
                            selection: $selectedProjectId,
                            options: sessionRouter.realCodexProjects.map { proj in
                                .init(value: proj.id, title: "\(proj.name) · \(proj.sessions.count) " + L10n.tr(zh: "会话", en: "sessions", ja: "セッション"))
                            }
                        )
                    }
                    .padding(.top, 2)
                }
            }
            
            
            // 第二步：选择会话形式
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.tr(zh: "对话形式", en: "Conversation Type", ja: "会話形式"))
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                
                Next5hSegmentedControl(
                    label: L10n.tr(zh: "对话形式", en: "Conversation", ja: "会話形式"),
                    selection: $isNewSession,
                    options: [
                        .init(value: true, title: L10n.tr(zh: "新建会话", en: "New session", ja: "新規会話")),
                        .init(value: false, title: L10n.tr(zh: "已有会话", en: "Existing", ja: "既存会話"))
                    ]
                )
                Text(L10n.tr(zh: "\(sessionRouter.realCodexProjects.count) 个项目 · \(availableSessions.count) 条可用会话", en: "\(sessionRouter.realCodexProjects.count) projects · \(availableSessions.count) sessions", ja: "\(sessionRouter.realCodexProjects.count) プロジェクト · \(availableSessions.count) 会話"))
                    .font(.system(size: 11))
                    .foregroundStyle(Next5hTheme.secondary)

                if !isNewSession {
                    VStack(alignment: .leading, spacing: 6) {
                        if availableSessions.isEmpty {
                            Text(L10n.tr(zh: "⚠️ 当前分类下暂无可追加的历史会话", en: "⚠️ No existing sessions under this category", ja: "⚠️ このカテゴリには追加可能なセッションがありません"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 2)
                        } else {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(isSpecificProject
                                     ? L10n.tr(zh: "项目内部会话:", en: "Project Session:", ja: "プロジェクト内セッション:")
                                     : L10n.tr(zh: "独立历史会话:", en: "Standalone Session:", ja: "通常セッション:"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Next5hMenuPicker(
                                    label: L10n.tr(zh: "选择会话", en: "Choose session", ja: "会話を選択"),
                                    selection: $selectedSessionId,
                                    options: sessionOptions
                                )
                            }
                            .padding(.top, 2)
                        }
                    }
                }
            }
        }

        .onChange(of: isSpecificProject) { _, _ in
            onScopeChanged()
        }
        .onChange(of: selectedProjectId) { _, _ in
            onProjectChanged()
        }
        .onChange(of: isNewSession) { _, _ in
            syncDestination()
        }
        .onChange(of: selectedSessionId) { _, _ in
            syncDestination()
        }
    }

    private var sessionOptions: [Next5hChoice<String>] {
        var options = availableSessions.map { Next5hChoice(value: $0.id, title: $0.title) }
        if selectedSessionId.isEmpty {
            options.insert(.init(value: "", title: L10n.tr(zh: "选择会话", en: "Choose session", ja: "会話を選択")), at: 0)
        }
        return options
    }
    
    private func onScopeChanged() {
        if isSpecificProject {
            if selectedProjectId.isEmpty || !sessionRouter.realCodexProjects.contains(where: { $0.id == selectedProjectId }) {
                selectedProjectId = sessionRouter.realCodexProjects.first?.id ?? ""
            }
        }
        selectedSessionId = availableSessions.first?.id ?? ""
        syncDestination()
    }
    
    private func onProjectChanged() {
        selectedSessionId = availableSessions.first?.id ?? ""
        syncDestination()
    }
    
    private func syncDestination() {
        let projScope: ProjectScope
        if isSpecificProject {
            let name = sessionRouter.realCodexProjects.first(where: { $0.id == selectedProjectId })?.name ?? "项目"
            projScope = .specific(id: selectedProjectId, name: name)
        } else {
            projScope = .noProject
        }
        
        let convAction: ConversationAction
        if isNewSession {
            convAction = .newSession
        } else {
            let title = availableSessions.first(where: { $0.id == selectedSessionId })?.title ?? "历史对话"
            convAction = .existing(id: selectedSessionId, title: title)
        }
        
        destination = TargetDestination(projectScope: projScope, conversationAction: convAction)
    }
}
