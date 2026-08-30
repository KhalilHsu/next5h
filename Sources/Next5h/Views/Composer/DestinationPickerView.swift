import SwiftUI

public struct DestinationPickerView: View {
    @Binding public var destination: TargetDestination
    @ObservedObject private var sessionRouter = SessionRouter.shared
    
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
                Text("🎯 发送目标 (Target Destination)")
                    .font(.headline)
                Spacer()
                Text("无项目会话: \(sessionRouter.noProjectSessions.count) 条 · 本地项目: \(sessionRouter.realCodexProjects.count) 个")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            // 第一步：选择项目归属
            VStack(alignment: .leading, spacing: 6) {
                Text("第一步：选择归属范围")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                
                Picker("", selection: $isSpecificProject) {
                    Text("🌐 无项目 (常规独立会话)").tag(false)
                    Text("📁 本地项目 (\(sessionRouter.realCodexProjects.count)个)").tag(true)
                }
                .pickerStyle(.segmented)
                
                if isSpecificProject {
                    HStack {
                        Text("所属项目:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Picker("", selection: $selectedProjectId) {
                            ForEach(sessionRouter.realCodexProjects) { proj in
                                Text("\(proj.name) (\(proj.sessions.count)个会话)").tag(proj.id)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        Spacer()
                    }
                    .padding(.top, 4)
                }
            }
            
            Divider()
            
            // 第二步：选择会话形式
            VStack(alignment: .leading, spacing: 6) {
                Text("第二步：选择对话形式")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                
                Picker("", selection: $isNewSession) {
                    Text("🆕 新建会话").tag(true)
                    Text("💬 追加到已有会话 (\(availableSessions.count)条)").tag(false)
                }
                .pickerStyle(.segmented)
                
                if !isNewSession {
                    VStack(alignment: .leading, spacing: 6) {
                        if availableSessions.isEmpty {
                            Text("⚠️ 当前分类下暂无可追加的历史会话")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 4)
                        } else {
                            HStack {
                                Text(isSpecificProject ? "项目内部会话:" : "独立历史会话:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Picker("", selection: $selectedSessionId) {
                                    ForEach(availableSessions) { sess in
                                        Text(sess.title).tag(sess.id)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                            .padding(.top, 4)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(nsColor: .controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
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
        // 重置选中的 session 为当前列表首项
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
