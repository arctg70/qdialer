import Foundation
import Contacts

// MARK: - Contacts Framework Service

@MainActor
final class ContactService {
    static let shared = ContactService()

    private let store = CNContactStore()

    private init() {}

    var authorizationStatus: CNAuthorizationStatus {
        CNContactStore.authorizationStatus(for: .contacts)
    }

    /// Request access to the user's contacts
    @discardableResult
    func requestAccess() async -> Bool {
        await withCheckedContinuation { continuation in
            self.store.requestAccess(for: .contacts) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    /// Fetch all contacts that have at least one phone number
    func fetchAllContacts() async -> [ContactModel] {
        let keys: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactMiddleNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactNicknameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactOrganizationNameKey as CNKeyDescriptor,
            CNContactThumbnailImageDataKey as CNKeyDescriptor,
        ]

        let request = CNContactFetchRequest(keysToFetch: keys)
        request.sortOrder = .userDefault

        var contacts = [ContactModel]()

        do {
            try store.enumerateContacts(with: request) { cnContact, _ in
                let model = ContactModel(contact: cnContact)
                guard !model.phoneNumbers.isEmpty else { return }
                contacts.append(model)
            }
        } catch {
            print("⚠️ Failed to fetch contacts: \(error.localizedDescription)")
        }

        return contacts
    }
}
