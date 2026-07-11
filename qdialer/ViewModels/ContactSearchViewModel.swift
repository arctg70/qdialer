import Foundation
import SwiftUI
import Combine
import Contacts

// MARK: - Contact Search ViewModel

@MainActor
final class ContactSearchViewModel: ObservableObject {
    // MARK: Published State

    @Published var searchText = ""
    @Published var contacts = [ContactModel]()
    @Published var filteredContacts = [ContactModel]()
    @Published var isAuthorized = false
    @Published var showPermissionDenied = false
    @Published var isLoading = false
    @Published var selectedContact: ContactModel?
    @Published var showCallAlert = false
    @Published var callHistory = [CallRecord]()

    // MARK: Dependencies

    private let contactService = ContactService.shared
    private let pinyinService = PinyinService.shared
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    /// If search text strips down to pure digits (3+), this is a direct-dial number
    var dialableNumber: String? {
        let digits = searchText.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        guard digits.count >= 3 else { return nil }
        return digits
    }

    /// Dial a raw phone number and save to call history
    func callRawNumber(_ number: String) {
        feedbackGenerator.impactOccurred()
        CallHistoryStore.shared.addCall(name: number, number: number)
        callHistory = CallHistoryStore.shared.records
        let clean = number.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        guard let url = URL(string: "tel://\(clean)"),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: Public API

    func setup() async {
        feedbackGenerator.prepare()
        CallHistoryStore.shared.load()
        callHistory = CallHistoryStore.shared.records
        await requestPermissionAndLoad()
        observeContactChanges()
    }

    /// Listen for external contact changes and reload automatically
    private func observeContactChanges() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name.CNContactStoreDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                // Small delay to let the store settle after the change
                try? await Task.sleep(nanoseconds: 500_000_000)
                await self?.loadContacts()
            }
        }
    }

    func requestPermissionAndLoad() async {
        let status = contactService.authorizationStatus

        switch status {
        case .notDetermined:
            let granted = await contactService.requestAccess()
            isAuthorized = granted
            if granted {
                await loadContacts()
            } else {
                showPermissionDenied = true
            }

        case .denied, .restricted:
            showPermissionDenied = true
            isAuthorized = false

        case .authorized:
            isAuthorized = true
            await loadContacts()

        @unknown default:
            break
        }
    }

    func loadContacts() async {
        isLoading = true
        contacts = await contactService.fetchAllContacts()
        isLoading = false
        refreshFilter()
    }

    // MARK: Input Handling

    /// Append a character to the search text
    func appendToSearch(_ letter: String) {
        searchText += letter
        feedbackGenerator.impactOccurred()
        refreshFilter()
    }

    /// Delete last character from search
    func deleteLastFromSearch() {
        guard !searchText.isEmpty else { return }
        searchText.removeLast()
        feedbackGenerator.impactOccurred()
        refreshFilter()
    }

    /// Clear entire search
    func clearSearch() {
        searchText = ""
        filteredContacts = []
    }

    /// Prepare to call a contact
    func selectContact(_ contact: ContactModel) {
        guard !contact.phoneNumbers.isEmpty else { return }
        selectedContact = contact
        showCallAlert = true
    }

    /// Dial immediately — saves to history
    /// - Parameter phoneNumber: if nil, uses the contact's first number
    ///   (when search text contains digits, auto-picks the number that matches the typed digits)
    func callContact(_ contact: ContactModel, phoneNumber: String? = nil) {
        let phone: String?
        if let pn = phoneNumber {
            phone = pn
        } else if searchText.contains(where: \.isNumber) {
            // Auto-match the phone number that corresponds to what the user typed
            let typedDigits = searchText.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            phone = contact.phoneNumbers.first { number in
                let clean = number.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                return clean.contains(typedDigits)
            } ?? contact.phoneNumbers.first
        } else {
            phone = contact.phoneNumbers.first
        }
        guard let phone else { return }
        feedbackGenerator.impactOccurred()
        CallHistoryStore.shared.addCall(name: contact.fullName, number: phone)
        callHistory = CallHistoryStore.shared.records
        let clean = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        guard let url = URL(string: "tel://\(clean)"),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: Filter

    func refreshFilter() {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else {
            filteredContacts = []
            selectedContact = nil
            return
        }

        // Score and sort every contact against the query
        let scored: [(ContactModel, Int)] = contacts.compactMap { contact in
            guard let score = pinyinService.matchQuery(query: query, contact: contact) else {
                return nil
            }
            return (contact, score)
        }
        .sorted { $0.1 > $1.1 }

        filteredContacts = scored.map(\.0)

        // Auto-select if only one perfect match remains
        if filteredContacts.count == 1 {
            selectedContact = filteredContacts.first
        } else {
            selectedContact = nil
        }
    }
}
