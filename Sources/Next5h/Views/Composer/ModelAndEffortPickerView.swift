import SwiftUI

public struct ModelAndEffortPickerView: View {
    @Binding public var model: DynamicCodexModel
    @Binding public var reasoningEffort: ReasoningEffort
    @Binding public var speed: SpeedPreference
    
    @ObservedObject private var catalogService = ModelCatalogService.shared
    @ObservedObject private var loc = LocalizationManager.shared
    
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
                Label(L10n.tr(zh: "模型与推理参数", en: "Model & Reasoning", ja: "モデル＆推論設定"), systemImage: "cpu")
                    .font(.subheadline.bold())
                Spacer()
                
                // 原生胶囊下拉菜单 [ 5.6 Sol 中 ⌵ ]
                Menu {
                    // 1. 动态官方模型子菜单
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
                            Text(L10n.tr(zh: "选择模型", en: "Select Model", ja: "モデル選択"))
                            Spacer()
                            Text(model.displayName)
                        }
                    }
                    
                    // 2. 动态推理强度子菜单
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
                            Text(L10n.tr(zh: "推理强度", en: "Reasoning Effort", ja: "推論レベル"))
                            Spacer()
                            Text(reasoningEffort.displayName)
                        }
                    }
                    
                    // 3. 动态速度子菜单
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
                                Text(L10n.tr(zh: "响应速度", en: "Response Speed", ja: "応答速度"))
                                Spacer()
                                Text(speed.displayName)
                            }
                        }
                    }
                    
                    Divider()
                    
                    Button {
                        model = catalogService.defaultModel
                        reasoningEffort = .medium
                        speed = .standard
                    } label: {
                        Label(L10n.tr(zh: "重置为默认设置", en: "Reset to Defaults", ja: "デフォルトに戻す"), systemImage: "arrow.counterclockwise")
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
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color(nsColor: .controlBackgroundColor)))
                    .overlay(Capsule().stroke(Color.secondary.opacity(0.25), lineWidth: 1))
                }
                .menuStyle(.borderlessButton)
            }
            
            // 当前参数概要说明
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.tr(zh: "当前模型", en: "Current Model", ja: "現在のモデル"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(model.displayName)
                        .font(.caption.bold())
                }
                
                Divider()
                    .frame(height: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.tr(zh: "推理强度", en: "Reasoning Effort", ja: "推論レベル"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(reasoningEffort.displayName)
                        .font(.caption.bold())
                }
                
                if model.supportsSpeedSelection {
                    Divider()
                        .frame(height: 20)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.tr(zh: "响应速度", en: "Speed", ja: "応答速度"))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(speed.displayName)
                            .font(.caption.bold())
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.secondary.opacity(0.05)))
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(nsColor: .controlBackgroundColor).opacity(0.6)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.15), lineWidth: 1))
        .onAppear {
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
