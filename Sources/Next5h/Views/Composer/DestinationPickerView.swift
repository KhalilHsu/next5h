import SwiftUI

public struct DestinationPickerView: View {
    @Binding public var destination: TargetDestination
    @ObservedObject private var sessionRouter = SessionRouter.shared
    @ObservedObject private var loc = LocalizationManager.shared
    
    private var isZh: Bool { loc.currentLanguage == .zh }
    
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
                Label(isZh ? "发送目标" : "Destination", systemImage: "arrow.triangle.branch")
                    .font(.subheadline.bold())
                Spacer()
                Text(isZh ? "无项目会话: \(sessionRouter.noProjectSessions.count) · 本地项目: \(sessionRouter.realCodexProjects.count)" : "Global: \(sessionRouter.noProjectSessions.count) · Local Projects: \(sessionRouter.realCodexProjects.count)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            // 第一步：选择项目归属
            VStack(alignment: .leading, spacing: 6) {
                Text(isZh ? "归属范围" : "Scope")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                
                Picker("", selection: $isSpecificProject) {
                    Text(isZh ? "🌐 无项目 (常规独立会话)" : "🌐 No Project (Standalone)").tag(false)
                    Text(isZh ? "📁 本地项目 (\(sessionRouter.realCodexProjects.count) 个)" : "📁 Local Projects (\(sessionRouter.realCodexProjects.count))").tag(true)
                }
                .pickerStyle(.segmented)
                
                if isSpecificProject {
                    HStack(spacing: 8) {
                        Text(isZh ? "所属项目:" : "Project:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Picker("", selection: $selectedProjectId) {
                            ForEach(sessionRouter.realCodexProjects) { proj in
                                Text("\(proj.name) (\(proj.sessions.count) " + (isZh ? "会话" : "Sessions") + ")").tag(proj.id)
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
                Text(isZh ? "对话形式" : "Conversation Type")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                
                Picker("", selection: $isNewSession) {
                    Text(isZh ? "🆕 新建独立会话" : "🆕 New Session").tag(true)
                    Text(isZh ? "💬 追加到已有会话 (\(availableSessions.count) 条)" : "💬 Existing Session (\(availableSessions.count))").tag(false)
                }
                .pickerStyle(.segmented)
                
                if !isNewSession {
                    VStack(alignment: .leading, spacing: 6) {
                        if availableSessions.isEmpty {
                            Text(isZh ? "⚠️ 当前分类下暂无可追加的历史会话" : "⚠️ No existing sessions under this category")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 2)
                        } else {
                            HStack(spacing: 8) {
                                Text(isSpecificProject ? (isZh ? "项目内部会话:" : "Project Session:") : (isZh ? "独立历史会话:" : "Standalone Session:"))
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
