import SwiftUI

/// 硬件休眠与无人值守支持指南弹窗
public struct PowerGuidelinesSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var loc = LocalizationManager.shared
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 弹窗顶部栏
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.shield.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)
                    Text(L10n.tr(
                        zh: "Mac 锁屏与休眠派发保障指南",
                        en: "Mac Lock Screen & Sleep Dispatch Guide",
                        ja: "画面ロック＆スリープ復帰ガイド"
                    ))
                    .font(.title3.bold())
                }
                Spacer()
                Button(L10n.tr(zh: "完成", en: "Done", ja: "完了")) {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // 核心总结 Alert
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.title3)
                            .foregroundStyle(.green)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.tr(
                                zh: "全自动息屏待命保活 (Standby Guard) 已内置生效",
                                en: "Built-in Automatic Standby Guard is Active",
                                ja: "自動画面消灯待機ガードが標準有効化されています"
                            ))
                            .font(.headline)
                            Text(L10n.tr(
                                zh: "只要队列中有待发任务，Next5h 会自动申请系统级防休眠断言（屏幕正常熄灭/锁屏，但系统内核清醒），07:00 等预定时间毫秒级准时派发，零终端操作，零特权依赖。",
                                en: "As long as jobs are pending, Next5h automatically keeps the kernel awake (display can sleep/lock). Dispatches right on time with zero terminal steps.",
                                ja: "未送信ジョブがある場合、Next5hが自動でカーネル稼働を維持（画面は正常に消灯/ロック）。端末操作不要で定刻にミリ秒単位で送信されます。"
                            ))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.green.opacity(0.08)))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.green.opacity(0.2), lineWidth: 1))
                    
                    // 场景一：Mac 台式机
                    PowerScenarioCard(
                        icon: "macstudio",
                        title: L10n.tr(
                            zh: "1. Mac 台式机 (Mac mini / Studio / Pro / iMac)",
                            en: "1. Desktop Mac (Mac mini / Studio / Pro / iMac)",
                            ja: "1. デスクトップ Mac (Mac mini / Studio / Pro / iMac)"
                        ),
                        badge: L10n.tr(zh: "全天候无忧", en: "24/7 Always Ready", ja: "常時稼働可能"),
                        badgeColor: .green,
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
                        title: L10n.tr(zh: "2. MacBook 笔记本 (Air / Pro)", en: "2. MacBook (Air / Pro)", ja: "2. MacBook (Air / Pro)"),
                        badge: L10n.tr(zh: "需注意开合盖", en: "Lid Status Matters", ja: "画面開閉状態に注意"),
                        badgeColor: .orange,
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
                        title: L10n.tr(zh: "3. 任务派发模式与锁屏兼容性", en: "3. Dispatch Mode & Lock Screen Compatibility", ja: "3. 送信モードと画面ロックの互換性"),
                        badge: L10n.tr(zh: "推荐静默模式", en: "Silent Mode Recommended", ja: "サイレント推奨"),
                        badgeColor: .blue,
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
                    
                    // 底层技术原理一览
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(L10n.tr(zh: "🛠 底层技术守护机制", en: "🛠 System Guard Mechanisms", ja: "🛠 技術的保護メカニズム"))
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            Spacer()
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(PowerGuardian.shared.isStandbyAssertionActive ? Color.green : Color.secondary.opacity(0.4))
                                    .frame(width: 7, height: 7)
                                Text(PowerGuardian.shared.isStandbyAssertionActive ?
                                     L10n.tr(zh: "息屏保活断言运行中", en: "Standby Guard Active", ja: "待機ガード稼働中") :
                                     L10n.tr(zh: "待命断言空闲 (无待发任务)", en: "Standby Idle", ja: "待機ガード停止中"))
                                    .font(.caption2)
                                    .foregroundStyle(PowerGuardian.shared.isStandbyAssertionActive ? .green : .secondary)
                            }
                        }
                        
                        Text(L10n.tr(
                            zh: "• IOPMAssertionCreateWithName：自动根据队列状态持有 PreventUserIdleSystemSleep 待命断言，屏幕可正常熄灭锁屏，但系统内核保持运转，实现 07:00 毫秒级准时派发。\n• 零终端依赖：普通权限完全原生支持，任务清空时自动释放断言以节省电量。\n• NetworkMonitor：自动检测并等待 Wi-Fi/以太网就绪后再发送，杜绝断网报错。",
                            en: "• IOPMAssertionCreateWithName: Automatically manages PreventUserIdleSystemSleep standby assertion, keeping kernel active while screen sleeps.\n• Zero Terminal Dependency: Completely native without extra privilege prompts; released when idle.\n• NetworkMonitor: Ensures network connectivity before sending to avoid failures.",
                            ja: "• IOPMAssertionCreateWithName: 待機ジョブがある間 PreventUserIdleSystemSleep を自動保持し、画面消灯時も定刻に即時送信。\n• 端末操作不要: 特権不要のネイティブ実装。完了時は自動解除し省電力を維持。\n• NetworkMonitor: ネットワーク疎通を確認してから安全に送信。"
                        ))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .controlBackgroundColor)))
                }
                .padding(20)
            }
        }
        .frame(minWidth: 580, idealWidth: 620, minHeight: 520, idealHeight: 580)
    }
}

/// 场景分类卡片
struct PowerScenarioCard: View {
    let icon: String
    let title: String
    let badge: String
    let badgeColor: Color
    let rows: [(scenario: String, status: String, note: String)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.orange)
                Text(title)
                    .font(.headline)
                Spacer()
                Text(badge)
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(badgeColor.opacity(0.15)))
                    .foregroundStyle(badgeColor)
            }
            
            Divider()
            
            VStack(spacing: 8) {
                ForEach(rows.indices, id: \.self) { idx in
                    let row = rows[idx]
                    HStack(alignment: .top, spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.scenario)
                                .font(.caption.bold())
                            Text(row.note)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(row.status)
                            .font(.caption.bold())
                            .foregroundStyle(row.status.contains("100%") ? .green : (row.status.contains("⚠️") ? .orange : (row.status.contains("❌") ? .red : .primary)))
                    }
                    .padding(.vertical, 2)
                    
                    if idx < rows.count - 1 {
                        Divider()
                            .opacity(0.5)
                    }
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(nsColor: .controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.15), lineWidth: 1))
    }
}

/// 快速提示条组件 (可嵌入在 Composer 与 Queue)
public struct PowerQuickTipBanner: View {
    @State private var showSheet: Bool = false
    @ObservedObject private var loc = LocalizationManager.shared
    
    public init() {}
    
    public var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.tr(
                    zh: "Mac 锁屏与休眠自动唤醒已受保护",
                    en: "Lock Screen & Sleep Auto-Wake Protected",
                    ja: "画面ロック＆スリープ時の自動復帰に対応"
                ))
                .font(.caption.bold())
                Text(L10n.tr(
                    zh: "Mac 台式机或 MacBook 开盖插电支持锁屏自动唤醒派发；合盖需外接显示器。",
                    en: "Desktop Mac or open plugged-in MacBook supports wake; clamshell requires display.",
                    ja: "デスクトップまたは開蓋・給電中のMacBookは自動復帰可能です。閉蓋時は外部ディスプレイが必要です。"
                ))
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                showSheet = true
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "questionmark.circle")
                    Text(L10n.tr(zh: "休眠规则", en: "Sleep Rules", ja: "スリープ規則"))
                }
                .font(.caption2.bold())
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .controlBackgroundColor).opacity(0.6)))
        .sheet(isPresented: $showSheet) {
            PowerGuidelinesSheetView()
        }
    }
}
