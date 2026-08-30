import Foundation
import Combine

public final class ModelCatalogService: ObservableObject {
    public static let shared = ModelCatalogService()
    
    @Published public var availableModels: [DynamicCodexModel] = []
    @Published public var defaultModel: DynamicCodexModel
    
    private var cacheWatcherSource: DispatchSourceFileSystemObject?
    
    private static var modelsCacheURL: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".codex/models_cache.json")
    }
    
    private init() {
        let loaded = ModelCatalogService.loadFromDisk()
        let initialDefault = loaded.first(where: { $0.isFlagship }) ?? loaded.first ?? DynamicCodexModel.fallbackDefault()
        self.availableModels = loaded
        self.defaultModel = initialDefault
        
        startFileWatcher()
    }
    
    /// 从 ~/.codex/models_cache.json 动态解析最新模型池
    public static func loadFromDisk() -> [DynamicCodexModel] {
        guard let data = try? Data(contentsOf: modelsCacheURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let modelsArray = json["models"] as? [[String: Any]] else {
            return [DynamicCodexModel.fallbackDefault()]
        }
        
        var results: [DynamicCodexModel] = []
        
        for item in modelsArray {
            let slug = item["slug"] as? String ?? ""
            if slug.isEmpty || slug == "gpt-reserve" || slug == "codex-auto-review" {
                continue
            }
            
            let rawName = item["display_name"] as? String ?? slug
            let desc = item["description"] as? String ?? ""
            let defaultEffortStr = item["default_reasoning_level"] as? String ?? "medium"
            let defaultEffort = ReasoningEffort.fromEffortString(defaultEffortStr)
            
            // 动态解析支持的 reasoning levels
            var levels: [ReasoningEffort] = []
            if let levelsList = item["supported_reasoning_levels"] as? [[String: Any]] {
                for l in levelsList {
                    if let eStr = l["effort"] as? String {
                        let parsed = ReasoningEffort.fromEffortString(eStr)
                        if !levels.contains(parsed) {
                            levels.append(parsed)
                        }
                    }
                }
            }
            if levels.isEmpty {
                levels = [.low, .medium, .high]
            }
            
            // 动态判断是否支持速度调节
            let hasSpeedTiers: Bool
            let speedTiers = item["additional_speed_tiers"] as? [Any] ?? []
            let serviceTiers = item["service_tiers"] as? [Any] ?? []
            hasSpeedTiers = !speedTiers.isEmpty || !serviceTiers.isEmpty
            
            // 美化展示名称: "GPT-5.6-Sol" -> "5.6 Sol", "GPT-5.4-Mini" -> "5.4 Mini"
            var cleanDisplayName = rawName.replacingOccurrences(of: "GPT-", with: "")
                                         .replacingOccurrences(of: "gpt-", with: "")
                                         .replacingOccurrences(of: "-", with: " ")
            if cleanDisplayName == "5.6 sol" { cleanDisplayName = "5.6 Sol" }
            if cleanDisplayName == "5.6 terra" { cleanDisplayName = "5.6 Terra" }
            if cleanDisplayName == "5.6 luna" { cleanDisplayName = "5.6 Luna" }
            if cleanDisplayName == "5.4 mini" { cleanDisplayName = "5.4 Mini" }
            
            let isFlagship = slug.contains("sol") || slug.contains("flagship") || results.isEmpty
            
            let model = DynamicCodexModel(
                slug: slug,
                displayName: cleanDisplayName,
                description: desc,
                supportedReasoningLevels: levels,
                defaultReasoningLevel: defaultEffort,
                supportsSpeedSelection: hasSpeedTiers,
                isFlagship: isFlagship
            )
            results.append(model)
        }
        
        return results.isEmpty ? [DynamicCodexModel.fallbackDefault()] : results
    }
    
    /// 实时监听 ~/.codex/models_cache.json 文件变更
    private func startFileWatcher() {
        let fd = open(ModelCatalogService.modelsCacheURL.path, O_EVTONLY)
        guard fd >= 0 else { return }
        
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .delete, .rename, .extend],
            queue: DispatchQueue.global()
        )
        
        source.setEventHandler { [weak self] in
            DispatchQueue.main.async {
                self?.reload()
            }
        }
        
        source.setCancelHandler {
            close(fd)
        }
        
        source.resume()
        self.cacheWatcherSource = source
    }
    
    public func reload() {
        let newModels = ModelCatalogService.loadFromDisk()
        self.availableModels = newModels
        self.defaultModel = newModels.first(where: { $0.isFlagship }) ?? newModels.first ?? DynamicCodexModel.fallbackDefault()
        print("🔄 [ModelCatalogService] 检测到 models_cache.json 变更，已动态刷新 \(newModels.count) 个可用模型: \(newModels.map { $0.displayName }.joined(separator: ", "))")
    }
    
    /// 校验并解析模型，当下架或失效时自动回退到当前最新的 defaultModel
    public func resolveModel(slugOrName: String) -> DynamicCodexModel {
        if let matched = availableModels.first(where: { $0.slug == slugOrName || $0.displayName == slugOrName }) {
            return matched
        }
        print("⚠️ [ModelCatalogService] 模型 [\(slugOrName)] 已从官方下架或不可用，动态回退至当前最新旗舰 [\(defaultModel.displayName)]")
        return defaultModel
    }
}
