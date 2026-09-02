import SwiftUI

public struct PermissionsCardView: View {
    @State private var hasNotification: Bool = true
    @State private var hasAccessibility: Bool = true
    @State private var hasPowerRTC: Bool = true
    @State private var showPowerSheet: Bool = false
    @ObservedObject private var loc = LocalizationManager.shared
    
    private var isZh: Bool { loc.currentLanguage == .zh }
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(isZh ? "🛡 系统权限与守护保障" : "🛡 System Permissions & Guard")
                    .font(.headline)
                Spacer()
                Button {
                    showPowerSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.shield")
                        Text(isZh ? "休眠与唤醒支持指南" : "Sleep & Wake Guide")
                    }
                    .font(.caption2)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            VStack(spacing: 8) {
                PermissionItemRow(title: isZh ? "系统通知权限" : "System Notifications", icon: "bell.badge.fill", isGranted: hasNotification)
                PermissionItemRow(title: isZh ? "电源管理与 RTC 硬件唤醒" : "Power Management & RTC Wake", icon: "bolt.batteryblock.fill", isGranted: hasPowerRTC)
                PermissionItemRow(title: isZh ? "辅助功能窗口模拟" : "Accessibility Window Control", icon: "hand.tap.fill", isGranted: hasAccessibility)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
        .sheet(isPresented: $showPowerSheet) {
            PowerGuidelinesSheetView()
        }
    }
}

struct PermissionItemRow: View {
    let title: String
    let icon: String
    let isGranted: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.caption)
            Spacer()
            Image(systemName: isGranted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(isGranted ? .green : .orange)
        }
    }
}
