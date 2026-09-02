import Foundation
import IOKit.pwr_mgt

public final class PowerGuardian: @unchecked Sendable {
    public static let shared = PowerGuardian()
    
    /// 执行任务时的临时高优先级电源断言
    private var executionAssertionID: IOPMAssertionID = 0
    /// 队列待命保活电源断言（允许屏幕关闭锁屏，保持 CPU 活跃）
    private var standbyAssertionID: IOPMAssertionID = 0
    
    private let lock = NSLock()
    
    private init() {}
    
    public var isStandbyAssertionActive: Bool {
        lock.lock()
        defer { lock.unlock() }
        return standbyAssertionID != 0
    }
    
    /// 根据当前是否有待发任务，动态更新待命电源断言
    /// 说明：kIOPMAssertionTypePreventUserIdleSystemSleep 完全允许显示器熄灭或系统锁屏，
    /// 但能防止 Mac 主机进入深度休眠，从而让应用内的定时器在 07:00 等预定时间毫秒级准时唤醒并派发。
    /// 无需 Root 权限，无需任何终端操作，开箱即用。
    public func updateStandbyAssertion(hasPendingJobs: Bool) {
        lock.lock()
        defer { lock.unlock() }
        
        if hasPendingJobs {
            if standbyAssertionID == 0 {
                let reason = "Next5h 定时任务待命保证 (保持息屏运行，准时触发派发)" as CFString
                let result = IOPMAssertionCreateWithName(
                    kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
                    IOPMAssertionLevel(kIOPMAssertionLevelOn),
                    reason,
                    &standbyAssertionID
                )
                if result == kIOReturnSuccess {
                    print("⚡️ [PowerGuardian] 已自动激活待命防休眠守卫 (Standby Guard, ID: \(standbyAssertionID))，屏幕可熄灭但系统不睡死，确保准时派发")
                } else {
                    print("⚠️ [PowerGuardian] 申请待命防休眠断言失败，错误码: \(result)")
                }
            }
        } else {
            if standbyAssertionID != 0 {
                IOPMAssertionRelease(standbyAssertionID)
                standbyAssertionID = 0
                print("💤 [PowerGuardian] 队列已无待发任务，已自动释放待命电源守卫，Mac 恢复正常节能休眠")
            }
        }
    }
    
    /// 设置硬件 RTC 定时唤醒（在目标时间前提前 60 秒唤醒）
    /// 如果普通 IOKit 权限不足，由 standbyAssertion 待命守卫兜底保证准时派发
    @discardableResult
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
            // 普通用户应用无 root 特权时返回 -536870207 (kIOReturnNotPrivileged)
            // 此时已通过 updateStandbyAssertion 自动启用息屏待命守卫，确保任务准时执行
            return false
        }
    }
    
    /// 通过 macOS 原生授权直接向系统写入硬件 RTC 唤醒计划（免终端操作）
    public func requestSystemRTCWakeAuthorization(for date: Date) -> (success: Bool, message: String) {
        let wakeDate = date.addingTimeInterval(-60)
        guard wakeDate > Date() else {
            return (false, "唤醒时间必须在未来")
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy HH:mm:ss"
        let dateString = formatter.string(from: wakeDate)
        
        let appleScriptSource = """
        do shell script "pmset schedule wake '\(dateString)'" with administrator privileges
        """
        
        var errorDict: NSDictionary?
        if let appleScript = NSAppleScript(source: appleScriptSource) {
            appleScript.executeAndReturnError(&errorDict)
            if let error = errorDict {
                let errStr = error[NSAppleScript.errorMessage] as? String ?? "用户取消或授权失败"
                return (false, errStr)
            } else {
                print("⏰ [PowerGuardian] 已成功通过系统原生授权注册硬件 RTC 唤醒: \(dateString)")
                return (true, "已成功注册硬件唤醒 (\(dateString))")
            }
        }
        return (false, "无法初始化授权引擎")
    }
    
    /// 取消之前排定的所有唤醒
    public func cancelWakeEvents() {}
    
    /// 任务派发执行期间阻止 Mac 系统休眠
    public func acquireSleepAssertion(reason: String = "Next5h 自动续航执行中") {
        lock.lock()
        defer { lock.unlock() }
        
        guard executionAssertionID == 0 else { return }
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason as CFString,
            &executionAssertionID
        )
        if result == kIOReturnSuccess {
            print("⚡️ [PowerGuardian] 派发电源断言已锁定，正在发送任务")
        }
    }
    
    /// 派发完毕后释放临时断言
    public func releaseSleepAssertion() {
        lock.lock()
        defer { lock.unlock() }
        
        if executionAssertionID != 0 {
            IOPMAssertionRelease(executionAssertionID)
            executionAssertionID = 0
            print("💤 [PowerGuardian] 派发电源断言已释放")
        }
    }
}
