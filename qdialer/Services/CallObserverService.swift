import Foundation
import CallKit
import UIKit

// MARK: - System Call Observer (CXCallObserver)

/// Observes system phone calls (incoming & outgoing) while the app is running.
/// Note: CXCallObserver does NOT provide the caller's phone number — only direction & timing.
@MainActor
final class CallObserverService: NSObject {
    static let shared = CallObserverService()

    private let callObserver = CXCallObserver()
    private var activeCalls: [UUID: Date] = [:]
    private(set) var isObserving = false

    private override init() {
        super.init()
    }

    /// Start observing system calls
    func startObserving() {
        guard !isObserving else { return }
        callObserver.setDelegate(self, queue: nil) // nil = main queue
        isObserving = true
    }
}

// MARK: - CXCallObserverDelegate

extension CallObserverService: CXCallObserverDelegate {
    nonisolated func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        // Extract values before crossing actor boundary (Swift 6 concurrency)
        let uuid = call.uuid
        let hasEnded = call.hasEnded
        let isOutgoing = call.isOutgoing

        Task { @MainActor in
            if hasEnded {
                // Call ended — record it if we tracked the start
                if let startTime = self.activeCalls.removeValue(forKey: uuid) {
                    let direction: CallRecord.CallDirection = isOutgoing ? .outgoing : .incoming

                    // Avoid duplicates: skip if a call was just manually recorded within 3 seconds
                    guard CallHistoryStore.shared.canRecordObservedCall(after: startTime) else { return }

                    CallHistoryStore.shared.addObservedCall(
                        direction: direction,
                        timestamp: startTime
                    )
                    // Post notification so the ViewModel can refresh
                    NotificationCenter.default.post(name: .init("CallHistoryDidChange"), object: nil)
                }
            } else if !activeCalls.keys.contains(uuid) {
                // First time we see this call — track it
                activeCalls[uuid] = Date()
            }
        }
    }
}
