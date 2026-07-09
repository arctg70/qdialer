import Foundation
import Contacts
import UIKit

// MARK: - Contact Model

struct ContactModel: Identifiable, Hashable {
    let id: String
    let givenName: String
    let familyName: String
    let fullName: String             // "San Zhang" (CNContact order)
    let reversedName: String         // "Zhang San" (family + given, for Chinese search)
    let nickname: String
    let phoneNumbers: [String]
    let emailAddresses: [String]
    let organization: String
    let thumbnailImageData: Data?

    // Cached pinyin data for fast search
    let pinyinFull: String          // "san zhang"
    let pinyinInitials: String      // "sz"
    let pinyinReversedFull: String  // "zhang san"
    let pinyinReversedInitials: String // "zs"
    let givenNamePinyinInitials: String
    let familyNamePinyinInitials: String
    let nicknamePinyin: String
    let orgPinyin: String
    let orgPinyinInitials: String

    init(contact: CNContact) {
        self.id = contact.identifier
        self.givenName = contact.givenName
        self.familyName = contact.familyName
        // Full name in CNContact order (givenName + familyName = "San Zhang")
        let nameParts = [contact.givenName, contact.familyName].filter { !$0.isEmpty }
        self.fullName = nameParts.isEmpty
            ? contact.organizationName
            : nameParts.joined(separator: " ")
        // Reversed order (familyName + givenName = "Zhang San") for Chinese initials search
        let revParts = [contact.familyName, contact.givenName].filter { !$0.isEmpty }
        self.reversedName = revParts.isEmpty
            ? contact.organizationName
            : revParts.joined(separator: " ")
        self.nickname = contact.nickname
        self.phoneNumbers = contact.phoneNumbers.map { $0.value.stringValue }
        self.emailAddresses = contact.emailAddresses.map { $0.value as String }
        self.organization = contact.organizationName
        self.thumbnailImageData = contact.thumbnailImageData

        // Precompute pinyin for fast search
        let pinyinService = PinyinService.shared
        self.pinyinFull = pinyinService.getPinyin(fullName)
        self.pinyinInitials = pinyinService.getPinyinInitials(fullName)
        self.pinyinReversedFull = pinyinService.getPinyin(reversedName)
        self.pinyinReversedInitials = pinyinService.getPinyinInitials(reversedName)
        self.givenNamePinyinInitials = pinyinService.getPinyinInitials(givenName)
        self.familyNamePinyinInitials = pinyinService.getPinyinInitials(familyName)
        self.nicknamePinyin = pinyinService.getPinyin(nickname)
        self.orgPinyin = pinyinService.getPinyin(organization)
        self.orgPinyinInitials = pinyinService.getPinyinInitials(organization)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ContactModel, rhs: ContactModel) -> Bool {
        lhs.id == rhs.id
    }

    var initials: String {
        let parts = fullName.split(separator: " ")
        return parts.compactMap { $0.first.map(String.init) }.joined().prefix(2).uppercased()
    }
}
