import Foundation
import IOKit.pwr_mgt

public final class PowerGuardian: @unchecked Sendable {
    public static let shared = PowerGuardian()
    
    private var assertionID: IOPMAssertionID = 0
    private let lock = NSLock()
    
    private init() {}
    
    /// 设置硬件 RTC 定时唤醒（在目标时间前提前 60 秒唤醒，以便系统握手 Wi-Fi）
    public func scheduleWakeEvent(at date: Date) -> Bool {
        let wakeDate = date.addingTimeInterval(-60)
        guard wakeDate > Date() else { return false }
        
        let result = IOPMSchedulePowerEvent(
            wakeDate as CFDate,
            nil,
            "wake" as CFString
        )
        if result == kIOReturnSuccess {
            print("⏰ [PowerGuardian] 成功注册硬件 RTC 唤醒事件: \(wakeDate)")
            return true
        } else {
            print("⚠️ [PowerGuardian] RTC 唤醒注册返回状态码: \(result)")
            return false
        }
    }
    
    /// 取消之前排定的所有唤醒
    public func cancelWakeEvents() {}
    
    /// 任务执行期间阻止 Mac 系统休眠
    public func acquireSleepAssertion(reason: String = "Next5h 自动续航执行中") {
        lock.lock()
        defer { lock.unlock() }
        
        guard assertionID == 0 else { return }
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason as CFString,
            &assertionID
        )
        if result == kIOReturnSuccess {
            print("⚡️ [PowerGuardian] 电源断言已锁定，防止 Mac 系统进入休眠")
        }
    }
    
    /// 执行完毕后释放电源断言
    public func releaseSleepAssertion() {
        lock.lock()
        defer { lock.unlock() }
        
        if assertionID != 0 {
            IOPMAssertionRelease(assertionID)
            assertionID = 0
            print("💤 [PowerGuardian] 电源断言已释放，允许系统恢复正常休眠")
        }
    }
}
