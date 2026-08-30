import SwiftUI

public struct ModelAndEffortPickerView: View {
    @Binding public var model: DynamicCodexModel
    @Binding public var reasoningEffort: ReasoningEffort
    @Binding public var speed: SpeedPreference
    
    @ObservedObject private var catalogService = ModelCatalogService.shared
    
    public init(
        model: Binding<DynamicCodexModel>,
        reasoningEffort: Binding<ReasoningEffort>,
        speed: Binding<SpeedPreference>
    ) {
        self._model = model
        self._reasoningEffort = reasoningEffort
        self._speed = speed
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🤖 模型与参数配置 (Codex)")
                    .font(.headline)
                Spacer()
                
                // 1:1 动态原生胶囊菜单 [ 5.6 Sol 中 ⌵ ]
                Menu {
                    // 1. 动态官方模型子菜单 (实时跟随 ~/.codex/models_cache.json 官方模型池)
                    Menu {
                        ForEach(catalogService.availableModels) { m in
                            Button {
                                model = m
                                if !m.supportedReasoningLevels.contains(reasoningEffort) {
                                    reasoningEffort = m.defaultReasoningLevel
                                }
                            } label: {
                                HStack {
                                    Text(m.displayName)
                                    if model.slug == m.slug {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("模型")
                            Spacer()
                            Text(model.displayName)
                        }
                    }
                    
                    // 2. 动态推理强度子菜单（完全由当前模型的能力定义）
                    Menu {
                        ForEach(model.supportedReasoningLevels) { effort in
                            Button {
                                reasoningEffort = effort
                            } label: {
                                HStack {
                                    Text(effort.displayName)
                                    if effort == reasoningEffort {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("推理强度")
                            Spacer()
                            Text(reasoningEffort.displayName)
                        }
                    }
                    
                    // 3. 动态速度子菜单 (仅在当前模型具备调速能力时展示)
                    if model.supportsSpeedSelection {
                        Menu {
                            ForEach(SpeedPreference.allCases) { s in
                                Button {
                                    speed = s
                                } label: {
                                    HStack {
                                        Text(s.displayName)
                                        if s == speed {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text("速度")
                                Spacer()
                                Text(speed.displayName)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // 4. 重置为默认设置
                    Button {
                        model = catalogService.defaultModel
                        reasoningEffort = .medium
                        speed = .standard
                    } label: {
                        Label("重置为默认设置", systemImage: "arrow.counterclockwise")
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("\(model.displayName) \(reasoningEffort.shortLabel)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.primary)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Color(nsColor: .controlBackgroundColor)))
                    .overlay(Capsule().stroke(Color.secondary.opacity(0.25), lineWidth: 1))
                }
                .menuStyle(.borderlessButton)
            }
            
            // 当前参数概要卡片
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("当前模型")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(model.displayName)
                        .font(.subheadline.bold())
                }
                
                Divider()
                    .frame(height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("推理强度")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(reasoningEffort.displayName)
                        .font(.subheadline.bold())
                }
                
                if model.supportsSpeedSelection {
                    Divider()
                        .frame(height: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("响应速度")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(speed.displayName)
                            .font(.subheadline.bold())
                    }
                }
                
                Spacer()
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.06)))
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(nsColor: .controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
        .onAppear {
            // 校验当前选中的 model 是否仍然在可用列表中，若已下架则自动重定向至最新 defaultModel
            if !catalogService.availableModels.contains(where: { $0.slug == model.slug }) {
                model = catalogService.defaultModel
            }
            if !model.supportedReasoningLevels.contains(reasoningEffort) {
                reasoningEffort = model.defaultReasoningLevel
            }
        }
        .onChange(of: model) { _, newModel in
            if !newModel.supportedReasoningLevels.contains(reasoningEffort) {
                reasoningEffort = newModel.defaultReasoningLevel
            }
        }
    }
}
