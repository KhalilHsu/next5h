import Foundation
import AppKit

public final class ForegroundUIDispatcher {
    public static let shared = ForegroundUIDispatcher()
    
    private init() {}
    
    /// 执行前台唤醒窗口并自动粘贴发送
    public func dispatch(job: ScheduledJob) async throws -> Bool {
        print("🖥️ [ForegroundUIDispatcher] 正在唤醒本地 ChatGPT / Codex 窗口并发送任务: \(job.title)")
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(job.prompt, forType: .string)
        
        let script = """
        tell application "ChatGPT"
            activate
        end tell
        delay 0.5
        tell application "System Events"
            keystroke "v" using command down
            delay 0.3
            key code 36
        end tell
        """
        
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
            if let err = error {
                print("⚠️ [ForegroundUIDispatcher] AppleScript 提示: \(err)")
            }
        }
        
        // 配合底层静默 CLI 发送双保险
        return try await SilentAPIDispatcher.shared.dispatch(job: job)
    }
}
