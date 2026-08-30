import SwiftUI

public struct PermissionsCardView: View {
    @State private var hasNotification: Bool = true
    @State private var hasAccessibility: Bool = true
    @State private var hasPowerRTC: Bool = true
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("🛡 系统权限与守护保障")
                .font(.headline)
            
            VStack(spacing: 8) {
                PermissionItemRow(title: "系统通知权限 (Notification)", icon: "bell.badge.fill", isGranted: hasNotification)
                PermissionItemRow(title: "电源管理与 RTC 硬件唤醒", icon: "bolt.batteryblock.fill", isGranted: hasPowerRTC)
                PermissionItemRow(title: "辅助功能 (Accessibility) 窗口模拟", icon: "hand.tap.fill", isGranted: hasAccessibility)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
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
