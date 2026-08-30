import Foundation
import Combine

public final class QuotaProbeEngine: ObservableObject {
    public static let shared = QuotaProbeEngine()
    
    @Published public var currentQuota: QuotaSnapshot
    @Published public var isProbing: Bool = false
    @Published public var probeLogs: [String] = []
    
    private var timer: Timer?
    private var secondTicker: Timer?
    
    private init() {
        let (isRunning, pid) = LocalCodexContextReader.shared.checkRunningChatGPTApp()
        self.currentQuota = QuotaSnapshot(
            usedPercent: 0,
            resetsAt: nil,
            windowMinutes: 300,
            isConnectedToChatGPTApp: isRunning,
            chatGPTPid: pid,
            statusDescription: "正在连接本地 Codex 客户端凭据..."
        )
        addLog("探针引擎启动，正在通过本地 ~/.codex/auth.json 请求官方后端...")
        startSecondTicker()
        refreshNow()
    }
    
    public func addLog(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let entry = "[\(formatter.string(from: Date()))] \(message)"
        DispatchQueue.main.async {
            self.probeLogs.insert(entry, at: 0)
            if self.probeLogs.count > 60 {
                self.probeLogs.removeLast()
            }
        }
    }
    
    /// 手动校准
    public func calibrateQuota(usedPercent: Double, resetsInSeconds: TimeInterval) {
        let targetReset = resetsInSeconds > 0 ? Date().addingTimeInterval(resetsInSeconds) : nil
        let snapshot = QuotaSnapshot(
            usedPercent: usedPercent,
            resetsAt: targetReset,
            windowMinutes: 300,
            weeklyUsedPercent: currentQuota.weeklyUsedPercent,
            weeklyResetsAt: currentQuota.weeklyResetsAt,
            capturedAt: Date(),
            isConnectedToChatGPTApp: currentQuota.isConnectedToChatGPTApp,
            chatGPTPid: currentQuota.chatGPTPid,
            statusDescription: usedPercent >= 100 ? "已手动校准为 5H 限流锁定" : "已校准为可用状态"
        )
        self.currentQuota = snapshot
        addLog("手动校准 5H 额度: \(Int(usedPercent))%，剩余解锁时间: \(snapshot.formattedRemainingTime)")
        rescheduleTimer()
    }
    
    /// 手动刷新
    public func refreshNow() {
        isProbing = true
        addLog("正在通过本地 ~/.codex/auth.json 请求官方实时 5H 额度...")
        
        Task {
            if let liveSnapshot = await LocalCodexContextReader.shared.fetchLiveQuota() {
                await MainActor.run {
                    self.currentQuota = liveSnapshot
                    self.isProbing = false
                    self.addLog("✅ 成功同步实时额度: 5H已用 \(Int(liveSnapshot.usedPercent))% · \(liveSnapshot.statusDescription)")
                    if let resetsAt = liveSnapshot.resetsAt {
                        self.addLog("⏰ 5H 窗口重置时间: \(resetsAt.formatted(date: .omitted, time: .standard))")
                    }
                    self.rescheduleTimer()
                }
            } else {
                await MainActor.run {
                    self.isProbing = false
                    self.addLog("⚠️ 未能从官方接口获取到数据，保持当前快照")
                    self.rescheduleTimer()
                }
            }
        }
    }
    
    private func startSecondTicker() {
        secondTicker = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.currentQuota.resetsAt != nil {
                self.objectWillChange.send()
            }
        }
    }
    
    private func rescheduleTimer() {
        timer?.invalidate()
        
        let remaining = currentQuota.remainingSeconds
        let interval: TimeInterval
        
        if remaining > 3600 {
            interval = 1800 // 30 分钟
        } else if remaining > 600 {
            interval = 600  // 10 分钟
        } else if remaining > 0 {
            interval = 180  // 3 分钟
        } else {
            interval = 1800 // 30 分钟
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.refreshNow()
        }
    }
}
