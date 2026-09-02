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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(L10n.tr(zh: "发送目标", en: "Destination", ja: "送信先"), systemImage: "arrow.triangle.branch")
                    .font(.subheadline.bold())
                Spacer()
                Text(L10n.tr(
                    zh: "无项目会话: \(sessionRouter.noProjectSessions.count) · 本地项目: \(sessionRouter.realCodexProjects.count)",
                    en: "Global: \(sessionRouter.noProjectSessions.count) · Local Projects: \(sessionRouter.realCodexProjects.count)",
                    ja: "通常セッション: \(sessionRouter.noProjectSessions.count) · プロジェクト: \(sessionRouter.realCodexProjects.count)"
                ))
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            
            // 第一步：选择项目归属
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.tr(zh: "归属范围", en: "Scope", ja: "所属スコープ"))
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                
                Picker("", selection: $isSpecificProject) {
                    Text(L10n.tr(zh: "🌐 无项目 (常规独立会话)", en: "🌐 No Project (Standalone)", ja: "🌐 プロジェクトなし (通常セッション)")).tag(false)
                    Text(L10n.tr(zh: "📁 本地项目 (\(sessionRouter.realCodexProjects.count) 个)", en: "📁 Local Projects (\(sessionRouter.realCodexProjects.count))", ja: "📁 ローカルプロジェクト (\(sessionRouter.realCodexProjects.count) 件)")).tag(true)
                }
                .pickerStyle(.segmented)
                
                if isSpecificProject {
                    HStack(spacing: 8) {
                        Text(L10n.tr(zh: "所属项目:", en: "Project:", ja: "対象プロジェクト:"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Picker("", selection: $selectedProjectId) {
                            ForEach(sessionRouter.realCodexProjects) { proj in
                                Text("\(proj.name) (\(proj.sessions.count) " + L10n.tr(zh: "会话", en: "Sessions", ja: "セッション") + ")").tag(proj.id)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        
                        Spacer()
                    }
                    .padding(.top, 2)
                }
            }
            
            Divider()
            
            // 第二步：选择会话形式
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.tr(zh: "对话形式", en: "Conversation Type", ja: "会話形式"))
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                
                Picker("", selection: $isNewSession) {
                    Text(L10n.tr(zh: "🆕 新建独立会话", en: "🆕 New Session", ja: "🆕 新規セッション作成")).tag(true)
                    Text(L10n.tr(zh: "💬 追加到已有会话 (\(availableSessions.count) 条)", en: "💬 Existing Session (\(availableSessions.count))", ja: "💬 既存セッションに追加 (\(availableSessions.count) 件)")).tag(false)
                }
                .pickerStyle(.segmented)
                
                if !isNewSession {
                    VStack(alignment: .leading, spacing: 6) {
                        if availableSessions.isEmpty {
                            Text(L10n.tr(zh: "⚠️ 当前分类下暂无可追加的历史会话", en: "⚠️ No existing sessions under this category", ja: "⚠️ このカテゴリには追加可能なセッションがありません"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 2)
                        } else {
                            HStack(spacing: 8) {
                                Text(isSpecificProject
                                     ? L10n.tr(zh: "项目内部会话:", en: "Project Session:", ja: "プロジェクト内セッション:")
                                     : L10n.tr(zh: "独立历史会话:", en: "Standalone Session:", ja: "通常セッション:"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Picker("", selection: $selectedSessionId) {
                                    ForEach(availableSessions) { sess in
                                        Text(sess.title).tag(sess.id)
                                    }
                                }
                                .pickerStyle(.menu)
                                .labelsHidden()
                                
                                Spacer()
                            }
                            .padding(.top, 2)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(nsColor: .controlBackgroundColor).opacity(0.6)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.15), lineWidth: 1))
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
        .onAppear {
            initFromDestination()
        }
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
    
    private func initFromDestination() {
        if case .specific(let id, _) = destination.projectScope {
            isSpecificProject = true
            selectedProjectId = id
        } else {
            isSpecificProject = false
            selectedProjectId = sessionRouter.realCodexProjects.first?.id ?? ""
        }
        
        if case .existing(let id, _) = destination.conversationAction {
            isNewSession = false
            selectedSessionId = id
        } else {
            isNewSession = true
            selectedSessionId = availableSessions.first?.id ?? ""
        }
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
