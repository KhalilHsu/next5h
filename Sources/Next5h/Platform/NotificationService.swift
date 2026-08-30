import Foundation
import UserNotifications

public final class NotificationService {
    public static let shared = NotificationService()
    
    private init() {}
    
    public func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("🔔 [NotificationService] 系统通知权限已获得")
            }
        }
    }
    
    public func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("⚠️ [NotificationService] 发送通知失败: \(error.localizedDescription)")
            }
        }
    }
    
    public func sendCompletionNotification(for job: ScheduledJob) {
        sendNotification(
            title: "🎯 Next5h 自动续航执行完成",
            body: "已成功为您发送任务: [\(job.title)]\n目标: \(job.destination.summary)"
        )
    }
}
