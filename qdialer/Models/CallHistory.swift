import Foundation

// MARK: - Call Record

struct CallRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let contactName: String
    let phoneNumber: String
    let timestamp: Date
    let direction: CallDirection

    enum CallDirection: String, Codable {
        case incoming
        case outgoing
    }
}

// MARK: - Call History Store

final class CallHistoryStore {
    nonisolated(unsafe) static let shared = CallHistoryStore()
    private let defaults = UserDefaults.standard
    private let key = "call_history"

    private init() {}

    private(set) var records: [CallRecord] = []

    /// Timestamp of the most recent manual record (used for dedup with CXCallObserver)
    private var lastManualRecordTime: Date?

    /// Load persisted history
    func load() {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([CallRecord].self, from: data) else {
            records = []
            return
        }
        records = decoded
    }

    /// Save an outgoing call (from within the app — has full contact info)
    func addCall(name: String, number: String) {
        let record = CallRecord(
            id: UUID(),
            contactName: name,
            phoneNumber: number,
            timestamp: Date(),
            direction: .outgoing
        )
        lastManualRecordTime = record.timestamp
        insertAndCap(record)
    }

    /// Save a call observed by CXCallObserver (no phone number available)
    func addObservedCall(direction: CallRecord.CallDirection, timestamp: Date) {
        let record = CallRecord(
            id: UUID(),
            contactName: "Unknown",
            phoneNumber: "",
            timestamp: timestamp,
            direction: direction
        )
        insertAndCap(record)
    }

    /// Skip if a manual call was just recorded (to avoid duplicates with tel://)
    func canRecordObservedCall(after time: Date) -> Bool {
        guard let last = lastManualRecordTime else { return true }
        return time.timeIntervalSince(last) > 3
    }

    /// Clear all history
    func clear() {
        records = []
        lastManualRecordTime = nil
        persist()
    }

    // MARK: - Private

    private func insertAndCap(_ record: CallRecord) {
        records.insert(record, at: 0)

        // Keep max 100 records
        if records.count > 100 {
            records = Array(records.prefix(100))
        }

        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        defaults.set(data, forKey: key)
    }
}
