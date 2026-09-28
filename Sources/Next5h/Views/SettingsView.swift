import SwiftUI
import AppKit

public struct SettingsView: View {
    @ObservedObject private var loc = LocalizationManager.shared
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // 头部应用品牌与版本
            HStack(spacing: 14) {
                if let appIcon = NSImage(named: "AppIcon") ?? NSApplication.shared.applicationIconImage {
                    Image(nsImage: appIcon)
                        .resizable()
                        .frame(width: 52, height: 52)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text("Next5h")
                            .font(.title2.bold())
                        Text("v1.0.2")
                            .font(.caption.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.accentColor.opacity(0.12)))
                            .foregroundStyle(Color.accentColor)
                    }
                    Text(L10n.tr(
                        zh: "macOS 原生 Codex 5H 额度自动续航工作台",
                        en: "Native macOS 5H Codex Quota Endurance Workbench",
                        ja: "macOS 原生 Codex 5H クォータ自動運用ワークベンチ"
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer()
            }
            
            Divider()
            
            // 1. 语言设置
            HStack {
                Text(L10n.tr(zh: "界面语言", en: "Language", ja: "表示言語"))
                    .font(.body)
                Spacer()
                Picker("", selection: Binding(
                    get: { loc.currentLanguage },
                    set: { loc.setLanguage($0) }
                )) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            
            // 2. 本地 Codex CLI 状态
            HStack {
                Text("Codex CLI")
                    .font(.body)
                Spacer()
                if let path = SilentAPIDispatcher.resolveCodexBinaryPath() {
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(L10n.tr(zh: "已就绪", en: "Ready", ja: "準備完了"))
                            .font(.caption.bold())
                            .foregroundStyle(.green)
                    }
                    .help(path)
                } else {
                    HStack(spacing: 5) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(L10n.tr(zh: "未检测到", en: "Not Found", ja: "未検出"))
                            .font(.caption.bold())
                            .foregroundStyle(.red)
                    }
                }
            }
            
            Divider()
            
            // 3. 快捷入口：呼出主工作台
            HStack {
                Text(L10n.tr(zh: "主控制台快捷键: ⌘O", en: "Main Workbench Shortcut: ⌘O", ja: "メイン画面のショートカット: ⌘O"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    (NSApplication.shared.delegate as? AppDelegate)?.showMainWindow()
                } label: {
                    Label(L10n.menuOpenWorkbench, systemImage: "macwindow")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
        }
        .padding(22)
        .frame(width: 440)
    }
}
