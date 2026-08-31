import Foundation
import Combine

public final class DispatchHistoryManager: ObservableObject {
    public static let shared = DispatchHistoryManager()
    
    @Published public var records: [DispatchHistoryRecord] = []
    
    private init() {
        loadPersistedRecords()
    }
    
    private var persistenceURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Next5h")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("execution_history.json")
    }
    
    private func loadPersistedRecords() {
        if let data = try? Data(contentsOf: persistenceURL),
           let saved = try? JSONDecoder().decode([DispatchHistoryRecord].self, from: data) {
            self.records = saved.sorted(by: { $0.dispatchedAt > $1.dispatchedAt })
        }
    }
    
    public func saveRecords() {
        if let data = try? JSONEncoder().encode(records) {
            try? data.write(to: persistenceURL)
        }
    }
    
    public func addRecord(_ record: DispatchHistoryRecord) {
        records.insert(record, at: 0)
        // 最多保留 500 条历史，防止无限膨胀
        if records.count > 500 {
            records = Array(records.prefix(500))
        }
        saveRecords()
    }
    
    public func deleteRecord(id: UUID) {
        records.removeAll(where: { $0.id == id })
        saveRecords()
    }
    
    public func clearAll() {
        records.removeAll()
        saveRecords()
    }
    
    /// 统计今日已成功派发次数
    public var todaySuccessCount: Int {
        let calendar = Calendar.current
        return records.filter { calendar.isDateInToday($0.dispatchedAt) && $0.isSuccess }.count
    }
}
