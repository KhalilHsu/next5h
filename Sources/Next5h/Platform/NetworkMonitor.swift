import Foundation
import Network

public final class NetworkMonitor: @unchecked Sendable {
    public static let shared = NetworkMonitor()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "Next5h.NetworkMonitor")
    private var isConnected: Bool = true
    private let lock = NSLock()
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.lock.lock()
            self?.isConnected = (path.status == .satisfied)
            self?.lock.unlock()
        }
        monitor.start(queue: queue)
    }
    
    public var currentStatus: Bool {
        lock.lock()
        defer { lock.unlock() }
        return isConnected
    }
    
    /// 唤醒后等待网络连接就绪（解决休眠唤醒后 2~5 秒 Wi-Fi 重连时延）
    public func waitForNetworkReadiness(timeout: TimeInterval = 10.0) async -> Bool {
        let startTime = Date()
        while Date().timeIntervalSince(startTime) < timeout {
            if currentStatus {
                return true
            }
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        }
        return currentStatus
    }
}
