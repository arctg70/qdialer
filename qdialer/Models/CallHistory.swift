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

    /// Load persisted history
    func load() {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([CallRecord].self, from: data) else {
            records = []
            return
        }
        records = decoded
    }

    /// Save an outgoing call
    func addCall(name: String, number: String) {
        let record = CallRecord(
            id: UUID(),
            contactName: name,
            phoneNumber: number,
            timestamp: Date(),
            direction: .outgoing
        )
        records.insert(record, at: 0)

        // Keep max 100 records
        if records.count > 100 {
            records = Array(records.prefix(100))
        }

        persist()
    }

    /// Clear all history
    func clear() {
        records = []
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        defaults.set(data, forKey: key)
    }
}
