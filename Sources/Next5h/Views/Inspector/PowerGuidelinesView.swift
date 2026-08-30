import SwiftUI

/// 硬件休眠与无人值守支持指南弹窗
public struct PowerGuidelinesSheetView: View {
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 弹窗顶部栏
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.shield.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)
                    Text("Mac 锁屏与休眠派发保障指南")
                        .font(.title3.bold())
                }
                Spacer()
                Button("完成") {
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
                        Image(systemName: "info.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("核心原则：台式机全天候畅通，MacBook 建议开盖插电")
                                .font(.headline)
                            Text("Next5h 通过芯片级 RTC 硬件在到点前 60 秒叫醒 Mac，配合底层静默 CLI 发送，无需登录解锁屏幕。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.blue.opacity(0.08)))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blue.opacity(0.2), lineWidth: 1))
                    
                    // 场景一：Mac 台式机
                    PowerScenarioCard(
                        icon: "macstudio",
                        title: "1. Mac 台式机 (Mac mini / Studio / Pro / iMac)",
                        badge: "全天候无忧",
                        badgeColor: .green,
                        rows: [
                            ("锁屏 / 显示器关闭", "✅ 100% 正常派发", "系统内核全速常驻，到点静默派发，无任何阻碍"),
                            ("系统深度休眠 (Sleep)", "✅ 自动唤醒并派发", "硬件 RTC 提前 60s 唤醒系统，握手网络后直接发送")
                        ]
                    )
                    
                    // 场景二：MacBook 笔记本
                    PowerScenarioCard(
                        icon: "laptopcomputer",
                        title: "2. MacBook 笔记本 (Air / Pro)",
                        badge: "需注意开合盖",
                        badgeColor: .orange,
                        rows: [
                            ("开盖 + 连接电源 (推荐)", "✅ 100% 稳定发送", "锁屏或休眠下均能由 RTC 准时唤醒并完成派发"),
                            ("开盖 + 纯电池供电", "⚠️ 支持，但受电量限制", "低电量或省电模式可能延迟网络握手，建议插电"),
                            ("合盖 + 外接显示器 (Clamshell)", "✅ 100% 稳定发送", "macOS 官方合盖台式机模式，插电即能持续运行"),
                            ("纯合盖 (无外接显示器)", "❌ 无法保证 (系统限制)", "Apple Silicon 固件为防过热会关闭 Wi-Fi 芯片并阻止网络唤醒")
                        ]
                    )
                    
                    // 场景三：发送模式选择
                    PowerScenarioCard(
                        icon: "paperplane.circle.fill",
                        title: "3. 任务派发模式与锁屏兼容性",
                        badge: "推荐静默模式",
                        badgeColor: .blue,
                        rows: [
                            ("后台静默 CLI 模式 (默认)", "✅ 锁屏兼容最佳", "直接调用底层 codex CLI，无视屏幕锁定，零界面打扰"),
                            ("前台 GUI 窗口模拟模式", "⚠️ 需解锁屏幕", "需模拟按键与粘贴，macOS 锁屏下会拦截虚拟按键")
                        ]
                    )
                    
                    // 底层技术原理一览
                    VStack(alignment: .leading, spacing: 8) {
                        Text("🛠 底层技术守护机制")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        
                        Text("• IOPMSchedulePowerEvent：直接向主板 RTC 实时时钟注册硬件定时唤醒。\n• IOPMAssertionCreateWithName：派发时申请 PreventUserIdleSystemSleep 电源断言防止中途休眠。\n• NetworkMonitor：自动检测并等待 Wi-Fi/以太网就绪后再发送，杜绝断网报错。")
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
    
    public init() {}
    
    public var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "bolt.badge.clock.fill")
                .font(.subheadline)
                .foregroundStyle(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Mac 锁屏与休眠自动唤醒已受保护")
                    .font(.caption.bold())
                Text("Mac 台式机或 MacBook 开盖插电支持锁屏自动唤醒派发；合盖需外接显示器。")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                showSheet = true
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "questionmark.circle")
                    Text("休眠规则")
                }
                .font(.caption2.bold())
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.orange.opacity(0.2), lineWidth: 1))
        .sheet(isPresented: $showSheet) {
            PowerGuidelinesSheetView()
        }
    }
}
