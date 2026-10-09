import SwiftUI

public struct PowerGuidelinesSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var loc = LocalizationManager.shared

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(L10n.tr(zh: "锁屏与休眠", en: "Lock screen & sleep", ja: "画面ロックとスリープ"))
                        .font(.system(size: 20, weight: .semibold))
                    Text(L10n.tr(zh: "找到适合你设备的发送方式", en: "Choose the setup that fits your Mac", ja: "Macに適した送信方法を確認"))
                        .font(.system(size: 12))
                        .foregroundStyle(Next5hTheme.secondary)
                }
                Spacer()
                Button(L10n.tr(zh: "完成", en: "Done", ja: "完了")) { dismiss() }
                    .buttonStyle(Next5hButtonStyle(kind: .primary))
                    .keyboardShortcut(.escape, modifiers: [])
            }
            .padding(24)

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.shield")
                            .foregroundStyle(Next5hTheme.mint)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(L10n.tr(zh: "推荐：后台发送，MacBook 开盖并接通电源", en: "Recommended: background delivery, with your MacBook open and plugged in", ja: "推奨：バックグラウンド送信、MacBookは開蓋して給電"))
                                .font(.system(size: 13, weight: .medium))
                            Text(L10n.tr(zh: "有待发任务时，Next5h 自动保持系统待命；屏幕仍可熄灭或锁定。", en: "Pending jobs keep the system ready. Your display can still sleep or lock.", ja: "未送信ジョブがある間は待機状態を維持。画面は消灯・ロックできます。"))
                                .font(.system(size: 12))
                                .foregroundStyle(Next5hTheme.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Next5hTheme.mint.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))

                    // 场景一：Mac 台式机
                    PowerScenarioCard(
                        icon: "macstudio",
                        title: L10n.tr(
                            zh: "Mac 台式机",
                            en: "Desktop Mac",
                            ja: "デスクトップ Mac"
                        ),
                        badge: L10n.tr(zh: "全天候无忧", en: "24/7 Always Ready", ja: "常時稼働可能"),
                        badgeColor: Next5hTheme.mint,
                        rows: [
                            (
                                L10n.tr(zh: "锁屏 / 显示器关闭", en: "Lock Screen / Display Sleep", ja: "画面ロック / ディスプレイ消灯"),
                                L10n.tr(zh: "✅ 100% 正常派发", en: "✅ 100% Dispatched", ja: "✅ 100% 送信完了"),
                                L10n.tr(zh: "系统内核全速常驻，到点静默派发，无任何阻碍", en: "Kernel active, silent dispatch without obstruction", ja: "カーネルが常時稼働し、静かに自動送信されます")
                            ),
                            (
                                L10n.tr(zh: "系统深度休眠 (Sleep)", en: "System Sleep", ja: "ディープスリープ (Sleep)"),
                                L10n.tr(zh: "✅ 自动唤醒并派发", en: "✅ Auto-wakes and Dispatches", ja: "✅ 自動復帰して送信"),
                                L10n.tr(zh: "硬件 RTC 提前 60s 唤醒系统，握手网络后直接发送", en: "RTC wakes system 60s ahead, waits for network then dispatches", ja: "RTCが60秒前にシステムを起動し、ネット接続後に送信します")
                            )
                        ]
                    )
                    
                    // 场景二：MacBook 笔记本
                    PowerScenarioCard(
                        icon: "laptopcomputer",
                        title: L10n.tr(zh: "MacBook", en: "MacBook", ja: "MacBook"),
                        badge: L10n.tr(zh: "需注意开合盖", en: "Lid Status Matters", ja: "画面開閉状態に注意"),
                        badgeColor: Next5hTheme.warning,
                        rows: [
                            (
                                L10n.tr(zh: "开盖 + 连接电源 (推荐)", en: "Lid Open + Plugged In (Recommended)", ja: "開蓋 + 電源接続 (推奨)"),
                                L10n.tr(zh: "✅ 100% 稳定发送", en: "✅ 100% Reliable", ja: "✅ 100% 安定送信"),
                                L10n.tr(zh: "锁屏或休眠下均能由 RTC 准时唤醒并完成派发", en: "RTC reliably wakes and dispatches during sleep or lock screen", ja: "RTCによりスリープや画面ロック時でも確実に復帰して送信")
                            ),
                            (
                                L10n.tr(zh: "开盖 + 纯电池供电", en: "Lid Open + On Battery", ja: "開蓋 + バッテリー駆動"),
                                L10n.tr(zh: "⚠️ 支持，但受电量限制", en: "⚠️ Supported, Battery Dependent", ja: "⚠️ 残量に依存"),
                                L10n.tr(zh: "低电量或省电模式可能延迟网络握手，建议插电", en: "Low battery or power saving may delay Wi-Fi handshake; AC recommended", ja: "省電力モード時はWi-Fi接続が遅延する可能性があるため給電を推奨")
                            ),
                            (
                                L10n.tr(zh: "合盖 + 外接显示器 (Clamshell)", en: "Clamshell Mode (Display Attached)", ja: "閉蓋 + 外部ディスプレイ (クラムシェル)"),
                                L10n.tr(zh: "✅ 100% 稳定发送", en: "✅ 100% Reliable", ja: "✅ 100% 安定送信"),
                                L10n.tr(zh: "macOS 官方合盖台式机模式，插电即能持续运行", en: "Official macOS clamshell mode; runs continuously when plugged in", ja: "macOS公式クラムシェルモードとして常時安定稼働")
                            ),
                            (
                                L10n.tr(zh: "纯合盖 (无外接显示器)", en: "Closed Lid (No External Display)", ja: "閉蓋 (外部ディスプレイなし)"),
                                L10n.tr(zh: "❌ 无法保证 (系统限制)", en: "❌ Not Guaranteed (OS Limit)", ja: "❌ 保証外 (OS仕様)"),
                                L10n.tr(zh: "Apple Silicon 固件为防过热会关闭 Wi-Fi 芯片并阻止网络唤醒", en: "Apple Silicon firmware cuts Wi-Fi to prevent overheating in bags", ja: "過熱防止のためApple SiliconファームウェアがWi-Fiを遮断します")
                            )
                        ]
                    )
                    
                    // 场景三：发送模式选择
                    PowerScenarioCard(
                        icon: "paperplane.circle.fill",
                        title: L10n.tr(zh: "发送方式", en: "Delivery mode", ja: "送信方法"),
                        badge: L10n.tr(zh: "推荐静默模式", en: "Silent Mode Recommended", ja: "サイレント推奨"),
                        badgeColor: Next5hTheme.accent,
                        rows: [
                            (
                                L10n.tr(zh: "后台静默 CLI 模式 (默认)", en: "Silent Background CLI (Default)", ja: "バックグラウンド CLI (デフォルト)"),
                                L10n.tr(zh: "✅ 锁屏兼容最佳", en: "✅ Best Lock Screen Compatibility", ja: "✅ 画面ロック完全対応"),
                                L10n.tr(zh: "直接调用底层 codex CLI，无视屏幕锁定，零界面打扰", en: "Directly invokes codex CLI, ignores lock screen, zero interruption", ja: "画面ロック状態でもCLIから直接バックグラウンド送信")
                            ),
                            (
                                L10n.tr(zh: "前台 GUI 窗口模拟模式", en: "Foreground GUI Simulation", ja: "前面 GUI ウィンドウ操作"),
                                L10n.tr(zh: "⚠️ 需解锁屏幕", en: "⚠️ Screen Unlock Required", ja: "⚠️ 画面ロック解除が必要"),
                                L10n.tr(zh: "需模拟按键与粘贴，macOS 锁屏下会拦截虚拟按键", en: "Requires keystroke simulation, blocked when screen is locked", ja: "キー入力シミュレーションが必要なためロック中は実行不可")
                            )
                        ]
                    )
                    
                    DisclosureGroup {
                        Text(L10n.tr(
                            zh: "• IOPMAssertionCreateWithName：自动根据队列状态持有 PreventUserIdleSystemSleep 待命断言，屏幕可正常熄灭锁屏，但系统内核保持运转，实现 07:00 毫秒级准时派发。\n• 零终端依赖：普通权限完全原生支持，任务清空时自动释放断言以节省电量。\n• NetworkMonitor：自动检测并等待 Wi-Fi/以太网就绪后再发送，杜绝断网报错。",
                            en: "• IOPMAssertionCreateWithName: Automatically manages PreventUserIdleSystemSleep standby assertion, keeping kernel active while screen sleeps.\n• Zero Terminal Dependency: Completely native without extra privilege prompts; released when idle.\n• NetworkMonitor: Ensures network connectivity before sending to avoid failures.",
                            ja: "• IOPMAssertionCreateWithName: 待機ジョブがある間 PreventUserIdleSystemSleep を自動保持し、画面消灯時も定刻に即時送信。\n• 端末操作不要: 特権不要のネイティブ実装。完了時は自動解除し省電力を維持。\n• NetworkMonitor: ネットワーク疎通を確認してから安全に送信。"
                        ))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)

                        HStack(spacing: 6) {
                            Circle().fill(PowerGuardian.shared.isStandbyAssertionActive ? Next5hTheme.mint : Next5hTheme.secondary).frame(width: 6, height: 6)
                            Text(PowerGuardian.shared.isStandbyAssertionActive
                                 ? L10n.tr(zh: "待命守卫运行中", en: "Standby guard active", ja: "待機ガード稼働中")
                                 : L10n.tr(zh: "待命守卫空闲", en: "Standby guard idle", ja: "待機ガード停止中"))
                                .font(.caption)
                        }
                        .padding(.top, 10)
                    } label: {
                        Text(L10n.tr(zh: "了解工作原理", en: "How it works", ja: "動作の仕組み"))
                            .font(.system(size: 13, weight: .medium))
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .background(Next5hTheme.surface)
        .foregroundStyle(Next5hTheme.ink)
        .tint(Next5hTheme.accent)
        .frame(minWidth: 600, idealWidth: 640, maxWidth: 700, minHeight: 540, idealHeight: 660, maxHeight: 720)
    }
}

struct PowerScenarioCard: View {
    let icon: String
    let title: String
    let badge: String
    let badgeColor: Color
    let rows: [(scenario: String, status: String, note: String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundStyle(Next5hTheme.secondary)
                Text(title).font(.system(size: 15, weight: .semibold))
                Spacer()
                Text(badge).font(.system(size: 11)).foregroundStyle(badgeColor)
            }
            ForEach(rows.indices, id: \.self) { index in
                let row = rows[index]
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 16) {
                        Text(row.scenario).font(.system(size: 13, weight: .medium))
                        Spacer(minLength: 8)
                        Text(cleanStatus(row.status))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(statusColor(row.status))
                    }
                    Text(row.note)
                        .font(.system(size: 12))
                        .foregroundStyle(Next5hTheme.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(2)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Next5hTheme.subtle, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private func cleanStatus(_ status: String) -> String {
        status.replacingOccurrences(of: "✅ ", with: "")
            .replacingOccurrences(of: "⚠️ ", with: "")
            .replacingOccurrences(of: "❌ ", with: "")
            .replacingOccurrences(of: "100% ", with: "")
    }

    private func statusColor(_ status: String) -> Color {
        if status.contains("⚠️") { return Next5hTheme.warning }
        if status.contains("❌") { return .red }
        return Next5hTheme.mint
    }
}

/// Composer 中的休眠规则提示。
public struct PowerQuickTipBanner: View {
    @State private var showSheet: Bool = false
    @ObservedObject private var loc = LocalizationManager.shared
    
    private let compact: Bool

    public init(compact: Bool = false) { self.compact = compact }
    
    public var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "checkmark.shield")
                .foregroundStyle(Next5hTheme.mint)
            VStack(alignment: .leading, spacing: 2) {
                Text(compact ? L10n.tr(zh: "锁屏与休眠", en: "Lock screen & sleep", ja: "画面ロックとスリープ") : L10n.tr(
                    zh: "Mac 锁屏与休眠自动唤醒已受保护",
                    en: "Lock Screen & Sleep Auto-Wake Protected",
                    ja: "画面ロック＆スリープ時の自動復帰に対応"
                ))
                .font(.caption.bold())
                if !compact {
                Text(L10n.tr(
                    zh: "Mac 台式机或 MacBook 开盖插电支持锁屏自动唤醒派发；合盖需外接显示器。",
                    en: "Desktop Mac or open plugged-in MacBook supports wake; clamshell requires display.",
                    ja: "デスクトップまたは開蓋・給電中のMacBookは自動復帰可能です。閉蓋時は外部ディスプレイが必要です。"
                ))
                .font(.caption2)
                .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Button {
                showSheet = true
            } label: {
                Next5hButtonLabel(L10n.tr(zh: "休眠规则", en: "Sleep Rules", ja: "スリープ規則"), systemImage: "questionmark.circle")
            }
            .buttonStyle(Next5hButtonStyle(kind: .quiet))
            .controlSize(.mini)
        }
        .font(.caption)
        .foregroundStyle(Next5hTheme.secondary)
        .sheet(isPresented: $showSheet) {
            PowerGuidelinesSheetView()
        }
    }
}
