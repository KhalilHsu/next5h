import SwiftUI

public struct JobComposerView: View {
    @ObservedObject private var queueManager = JobQueueManager.shared
    @ObservedObject private var appState = AppState.shared
    @ObservedObject private var quotaEngine = QuotaProbeEngine.shared
    @ObservedObject private var catalogService = ModelCatalogService.shared
    
    @State private var editingJobId: UUID? = nil
    
    @State private var title: String = ""
    @State private var prompt: String = ""
    @State private var model: DynamicCodexModel = DynamicCodexModel.fallbackDefault()
    @State private var reasoningEffort: ReasoningEffort = .low
    @State private var speed: SpeedPreference = .standard
    @State private var destination: TargetDestination = TargetDestination()
    @State private var strategy: ScheduleStrategy = .dailyAtTime(hour: 7, minute: 0)
    @State private var dispatchMode: DispatchMode = .silentAPI
    
    @State private var showSuccessBanner: Bool = false
    @State private var bannerText: String = "任务已成功加入待发调度队列！"
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 顶部状态条 (自适应新建 vs 编辑模式)
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        if editingJobId != nil {
                            HStack(spacing: 6) {
                                Text("✏️ 编辑任务")
                                    .font(.title2.bold())
                                    .foregroundStyle(.orange)
                                Text("(\(title))")
                                    .font(.title3.bold())
                                    .foregroundStyle(.secondary)
                            }
                            Text("修改 User Query 或目标参数，点击下方“保存任务修改”即可直接更新")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("📝 任务编排工作台")
                                .font(.title2.bold())
                            Text("预存 Prompt 与目标参数，到点自动将 User Query 派发至本地 Codex 客户端")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if editingJobId != nil {
                        Button("取消编辑") {
                            cancelEditing()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    } else {
                        Button("🔄 载入默认模板") {
                            loadPreset(ScheduledJob.makeDefaultPreset())
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .padding(.bottom, 2)
                
                // 任务名称
                VStack(alignment: .leading, spacing: 4) {
                    Text("任务名称")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    TextField("例如: 每日 07:00 初始问候 / 重构核心调度模块", text: $title)
                        .textFieldStyle(.roundedBorder)
                }
                
                // Prompt 编辑器
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("User Query (Prompt 内容)")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(prompt.count) 字符")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    TextEditor(text: $prompt)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 110)
                        .padding(6)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .textBackgroundColor)))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                }
                
                // 两级路由目标 (先选项目 -> 会话/新建)
                DestinationPickerView(destination: $destination)
                
                // 动态模型与参数选择器 (实时从 ~/.codex/models_cache.json 渲染)
                ModelAndEffortPickerView(model: $model, reasoningEffort: $reasoningEffort, speed: $speed)
                
                // 发送模式
                DispatchModePickerView(dispatchMode: $dispatchMode)
                
                // 触发时机 (每日定时 / 5H解封 / 延时 / 具体时间)
                StrategyPickerView(strategy: $strategy)
                
                // 操作栏 (自适应“加入队列”与“保存修改”)
                HStack {
                    if showSuccessBanner {
                        Label(bannerText, systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.subheadline.bold())
                    }
                    
                    Spacer()
                    
                    if editingJobId != nil {
                        Button(action: saveEditedJob) {
                            Label("💾 保存任务修改", systemImage: "checkmark.circle.fill")
                                .padding(.horizontal, 18)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        .controlSize(.large)
                        .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    } else {
                        Button(action: scheduleNewJob) {
                            Label("🚀 加入待发调度队列", systemImage: "paperplane.fill")
                                .padding(.horizontal, 18)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding(.top, 6)
            }
            .padding(20)
            .frame(maxWidth: 800)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .onAppear {
            if let editing = appState.editingJob {
                loadForEditing(editing)
                appState.editingJob = nil
            } else if editingJobId == nil && title.isEmpty && prompt.isEmpty {
                loadPreset(ScheduledJob.makeDefaultPreset())
            }
        }
    }
    
    private func loadForEditing(_ job: ScheduledJob) {
        self.editingJobId = job.id
        self.title = job.title
        self.prompt = job.prompt
        self.model = catalogService.resolveModel(slugOrName: job.model.slug)
        self.reasoningEffort = job.reasoningEffort
        self.speed = job.speed
        self.destination = job.destination
        self.strategy = job.strategy
        self.dispatchMode = job.dispatchMode
    }
    
    private func loadPreset(_ job: ScheduledJob) {
        self.editingJobId = nil
        self.title = job.title
        self.prompt = job.prompt
        self.model = catalogService.resolveModel(slugOrName: job.model.slug)
        self.reasoningEffort = job.reasoningEffort
        self.speed = job.speed
        self.destination = job.destination
        self.strategy = job.strategy
        self.dispatchMode = job.dispatchMode
    }
    
    private func cancelEditing() {
        self.editingJobId = nil
        loadPreset(ScheduledJob.makeDefaultPreset())
        appState.selectedTab = .queue
    }
    
    private func saveEditedJob() {
        guard let id = editingJobId else { return }
        let safeModel = catalogService.resolveModel(slugOrName: model.slug)
        
        let updatedJob = ScheduledJob(
            id: id,
            title: title.isEmpty ? "自动化任务" : title,
            prompt: prompt,
            model: safeModel,
            reasoningEffort: reasoningEffort,
            speed: speed,
            destination: destination,
            strategy: strategy,
            dispatchMode: dispatchMode,
            status: .pending
        )
        
        queueManager.updateJob(updatedJob)
        
        bannerText = "任务修改已成功保存！"
        showSuccessBanner = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.editingJobId = nil
            self.showSuccessBanner = false
            self.appState.selectedTab = .queue
        }
    }
    
    private func scheduleNewJob() {
        let safeModel = catalogService.resolveModel(slugOrName: model.slug)
        let newJob = ScheduledJob(
            id: UUID(),
            title: title.isEmpty ? "自动化任务" : title,
            prompt: prompt,
            model: safeModel,
            reasoningEffort: reasoningEffort,
            speed: speed,
            destination: destination,
            strategy: strategy,
            dispatchMode: dispatchMode,
            status: .pending
        )
        queueManager.addJob(newJob)
        
        bannerText = "任务已成功加入待发调度队列！"
        showSuccessBanner = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.showSuccessBanner = false
            self.appState.selectedTab = .queue
        }
    }
}
