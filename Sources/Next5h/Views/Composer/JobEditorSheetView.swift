import SwiftUI

public struct JobEditorSheetView: View {
    @ObservedObject private var queueManager = JobQueueManager.shared
    @ObservedObject private var appState = AppState.shared
    @ObservedObject private var catalogService = ModelCatalogService.shared
    @Environment(\.dismiss) private var dismiss
    
    private let editingJob: ScheduledJob?
    
    @State private var title: String = ""
    @State private var prompt: String = ""
    @State private var model: DynamicCodexModel = DynamicCodexModel.fallbackDefault()
    @State private var reasoningEffort: ReasoningEffort = .low
    @State private var speed: SpeedPreference = .standard
    @State private var destination: TargetDestination = TargetDestination()
    @State private var strategy: ScheduleStrategy = .dailyAtTime(hour: 7, minute: 0)
    @State private var dispatchMode: DispatchMode = .silentAPI
    
    @State private var selectedTemplateIndex: Int? = nil
    
    public init(job: ScheduledJob? = nil) {
        self.editingJob = job
    }
    
    private var isExistingJob: Bool {
        guard let id = editingJob?.id else { return false }
        return queueManager.jobs.contains(where: { $0.id == id })
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // 1. 顶部标题栏
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemName: isExistingJob ? "pencil.circle.fill" : "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(isExistingJob ? Color.orange : Color.accentColor)
                        
                        Text(isExistingJob ? "编辑任务" : "新建调度任务")
                            .font(.title3.bold())
                    }
                    
                    Text(isExistingJob ? "修改已排定任务的参数与 User Query 内容" : "配置到点自动派发至本地 Codex 客户端的 User Query")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button {
                    closeSheet()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary.opacity(0.7))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 12)
            
            Divider()
            
            // 2. 表单内容可滚动区域
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 若是新建模式，提供快捷场景模板 Pill
                    if !isExistingJob {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("⚡️ 快捷模板填入 (可选)")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            
                            HStack(spacing: 8) {
                                templateButton(
                                    title: "🌅 每日早晨打卡",
                                    index: 0,
                                    preset: ScheduledJob.makeDefaultPreset()
                                )
                                
                                templateButton(
                                    title: "⚡️ 5H 解封自动发",
                                    index: 1,
                                    preset: ScheduledJob(
                                        title: "⚡️ 5H 解封自动发送",
                                        prompt: "请帮我检查并 Review 当前项目的最新提交和变更分支",
                                        model: catalogService.defaultModel,
                                        reasoningEffort: .medium,
                                        speed: .standard,
                                        destination: TargetDestination(),
                                        strategy: .autoOnQuotaReset(safetyDelayMinutes: 1),
                                        dispatchMode: .silentAPI
                                    )
                                )
                                
                                templateButton(
                                    title: "☕️ 延时 3 小时提醒",
                                    index: 2,
                                    preset: ScheduledJob(
                                        title: "☕️ 3 小时后自动总结",
                                        prompt: "总结今天的编码进展与待办事项",
                                        model: catalogService.defaultModel,
                                        reasoningEffort: .low,
                                        speed: .standard,
                                        destination: TargetDestination(),
                                        strategy: .delayDuration(seconds: 10800),
                                        dispatchMode: .silentAPI
                                    )
                                )
                            }
                        }
                        .padding(.top, 4)
                    }
                    
                    // 任务名称
                    VStack(alignment: .leading, spacing: 6) {
                        Text("任务名称")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        TextField("例如: 每日 07:00 初始问候 / 重构核心调度模块", text: $title)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // User Query (Prompt) 输入区
                    VStack(alignment: .leading, spacing: 6) {
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
                            .frame(minHeight: 100, maxHeight: 160)
                            .padding(6)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .textBackgroundColor)))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                    }
                    
                    // 发送目标
                    DestinationPickerView(destination: $destination)
                    
                    // 模型与参数
                    ModelAndEffortPickerView(model: $model, reasoningEffort: $reasoningEffort, speed: $speed)
                    
                    // 发送模式
                    DispatchModePickerView(dispatchMode: $dispatchMode)
                    
                    // 触发策略
                    StrategyPickerView(strategy: $strategy)
                }
                .padding(20)
            }
            
            Divider()
            
            // 3. 底部操作栏
            HStack {
                Text("提示: 按 Esc 取消，按 ⌘Return 保存")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button("取消") {
                    closeSheet()
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .keyboardShortcut(.escape, modifiers: [])
                
                Button {
                    saveJob()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isExistingJob ? "checkmark.circle.fill" : "paperplane.fill")
                        Text(isExistingJob ? "保存任务修改" : "加入调度队列")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(isExistingJob ? .orange : .accentColor)
                .controlSize(.regular)
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(minWidth: 620, idealWidth: 660, maxWidth: 720, minHeight: 520, maxHeight: 680)
        .onAppear {
            if let job = editingJob {
                loadJob(job)
            } else {
                // 新建模式下默认保持干净空白
                self.title = ""
                self.prompt = ""
                self.model = catalogService.defaultModel
                self.reasoningEffort = .low
                self.speed = .standard
                self.destination = TargetDestination()
                self.strategy = .dailyAtTime(hour: 7, minute: 0)
                self.dispatchMode = .silentAPI
            }
        }
    }
    
    @ViewBuilder
    private func templateButton(title: String, index: Int, preset: ScheduledJob) -> some View {
        Button {
            selectedTemplateIndex = index
            loadJob(preset)
        } label: {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(selectedTemplateIndex == index ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.08)))
                .overlay(Capsule().stroke(selectedTemplateIndex == index ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: 1))
                .foregroundStyle(selectedTemplateIndex == index ? Color.accentColor : Color.primary)
        }
        .buttonStyle(.plain)
    }
    
    private func loadJob(_ job: ScheduledJob) {
        self.title = job.title
        self.prompt = job.prompt
        self.model = catalogService.resolveModel(slugOrName: job.model.slug)
        self.reasoningEffort = job.reasoningEffort
        self.speed = job.speed
        self.destination = job.destination
        self.strategy = job.strategy
        self.dispatchMode = job.dispatchMode
    }
    
    private func closeSheet() {
        dismiss()
        appState.closeJobSheet()
    }
    
    private func saveJob() {
        let safeModel = catalogService.resolveModel(slugOrName: model.slug)
        let resolvedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "自动化任务" : title
        
        if let existing = editingJob {
            let updated = ScheduledJob(
                id: existing.id,
                title: resolvedTitle,
                prompt: prompt,
                model: safeModel,
                reasoningEffort: reasoningEffort,
                speed: speed,
                destination: destination,
                strategy: strategy,
                dispatchMode: dispatchMode,
                status: .pending
            )
            queueManager.updateJob(updated)
        } else {
            let newJob = ScheduledJob(
                id: UUID(),
                title: resolvedTitle,
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
        }
        
        closeSheet()
    }
}
