import Foundation
import Combine

public struct ProbeLogEntry: Identifiable, Equatable {
    public let id = UUID()
    public let timestamp: Date
    public let zh: String
    public let en: String
    public let ja: String
    
    public init(timestamp: Date = Date(), zh: String, en: String, ja: String? = nil) {
        self.timestamp = timestamp
        self.zh = zh
        self.en = en
        self.ja = ja ?? en
    }
    
    public func formattedMessage(lang: AppLanguage = LocalizationManager.shared.currentLanguage) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let text: String
        switch lang {
        case .zh: text = zh
        case .en: text = en
        case .ja: text = ja
        }
        return "[\(formatter.string(from: timestamp))] \(text)"
    }
    
    public func formattedMessage(isZh: Bool) -> String {
        return formattedMessage(lang: isZh ? .zh : .en)
    }
}

public final class QuotaProbeEngine: ObservableObject {
    public static let shared = QuotaProbeEngine()
    
    @Published public var currentQuota: QuotaSnapshot
    @Published public var isProbing: Bool = false
    @Published public var probeLogEntries: [ProbeLogEntry] = []
    
    public var probeLogs: [String] {
        return probeLogEntries.map { $0.formattedMessage() }
    }
    
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
            statusDescription: L10n.tr(
                zh: "正在连接本地 Codex 凭据...",
                en: "Connecting to Codex credentials...",
                ja: "ローカル Codex 認証情報を確認中..."
            )
        )
        addLog(
            zh: "探针引擎启动，正在通过本地 ~/.codex/auth.json 请求官方后端...",
            en: "Probe engine started, querying official backend via ~/.codex/auth.json...",
            ja: "プローブエンジン起動、~/.codex/auth.json から公式APIに接続中..."
        )
        startSecondTicker()
        refreshNow()
    }
    
    public func addLog(zh: String, en: String, ja: String? = nil) {
        let entry = ProbeLogEntry(timestamp: Date(), zh: zh, en: en, ja: ja)
        DispatchQueue.main.async {
            self.probeLogEntries.insert(entry, at: 0)
            if self.probeLogEntries.count > 60 {
                self.probeLogEntries.removeLast()
            }
        }
    }
    
    public func addLog(_ message: String) {
        addLog(zh: message, en: message, ja: message)
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
            statusDescription: usedPercent >= 100
                ? L10n.tr(zh: "已手动校准为 5H 限流锁定", en: "Manually calibrated to 5H locked", ja: "手動で5H制限中に設定")
                : L10n.tr(zh: "已校准为可用状态", en: "Calibrated to available", ja: "利用可能に設定")
        )
        self.currentQuota = snapshot
        addLog(
            zh: "手动校准 5H 额度: \(Int(usedPercent))%，剩余解锁时间: \(snapshot.formattedRemainingTime)",
            en: "Manually calibrated 5H quota: \(Int(usedPercent))%, resets in: \(snapshot.formattedRemainingTime)",
            ja: "手動校正 5Hクォータ: \(Int(usedPercent))%、リセットまで: \(snapshot.formattedRemainingTime)"
        )
        rescheduleTimer()
    }
    
    /// 手动刷新
    public func refreshNow() {
        isProbing = true
        addLog(
            zh: "正在通过本地 ~/.codex/auth.json 请求官方实时 5H 额度...",
            en: "Requesting live 5H quota from official API via ~/.codex/auth.json...",
            ja: "ローカル ~/.codex/auth.json から公式リアルタイム5Hクォータを取得中..."
        )
        
        Task {
            if let liveSnapshot = await LocalCodexContextReader.shared.fetchLiveQuota() {
                await MainActor.run {
                    self.currentQuota = liveSnapshot
                    self.isProbing = false
                    let used = Int(liveSnapshot.usedPercent)
                    self.addLog(
                        zh: "✅ 成功同步实时额度: 5H已用 \(used)% · \(liveSnapshot.statusDescription)",
                        en: "✅ Live quota synced: 5H used \(used)% · \(liveSnapshot.statusDescription)",
                        ja: "✅ リアルタイムクォータ同期成功: 5H使用率 \(used)% · \(liveSnapshot.statusDescription)"
                    )
                    if let resetsAt = liveSnapshot.resetsAt {
                        let timeStr = resetsAt.formatted(date: .omitted, time: .standard)
                        self.addLog(
                            zh: "⏰ 5H 窗口重置时间: \(timeStr)",
                            en: "⏰ 5H window resets at: \(timeStr)",
                            ja: "⏰ 5Hウィンドウリセット日時: \(timeStr)"
                        )
                    }
                    self.rescheduleTimer()
                }
            } else {
                await MainActor.run {
                    self.isProbing = false
                    self.addLog(
                        zh: "⚠️ 未能从官方接口获取到数据，保持当前快照",
                        en: "⚠️ Failed to fetch data from official API, keeping current snapshot",
                        ja: "⚠️ 公式APIからデータを取得できませんでした。現在の状態を維持します"
                    )
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
