import Foundation
import Contacts
import UIKit

// MARK: - Contact Model

struct ContactModel: Identifiable, Hashable {
    let id: String
    let givenName: String
    let middleName: String
    let familyName: String
    let fullName: String             // "San Middle Zhang" (CNContact order)
    let reversedName: String         // "Zhang San Middle" (family + given, for Chinese search)
    let nickname: String
    let phoneNumbers: [String]
    let emailAddresses: [String]
    let organization: String
    let thumbnailImageData: Data?

    // Cached pinyin data for fast search
    let pinyinFull: String          // "san middle zhang"
    let pinyinInitials: String      // "smz"
    let pinyinReversedFull: String  // "zhang san middle"
    let pinyinReversedInitials: String // "zsm"
    let givenNamePinyinInitials: String
    let middleNamePinyin: String
    let middleNamePinyinInitials: String
    let familyNamePinyinInitials: String
    let nicknamePinyin: String
    let orgPinyin: String
    let orgPinyinInitials: String

    init(contact: CNContact) {
        self.id = contact.identifier
        self.givenName = contact.givenName
        self.middleName = contact.middleName
        self.familyName = contact.familyName
        // Full name: givenName + middleName + familyName = "San Middle Zhang"
        let nameParts = [contact.givenName, contact.middleName, contact.familyName].filter { !$0.isEmpty }
        self.fullName = nameParts.isEmpty
            ? contact.organizationName
            : nameParts.joined(separator: " ")
        // Reversed order for Chinese search: familyName + givenName + middleName = "Zhang San Middle"
        let revParts = [contact.familyName, contact.givenName, contact.middleName].filter { !$0.isEmpty }
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
        self.middleNamePinyin = pinyinService.getPinyin(middleName)
        self.middleNamePinyinInitials = pinyinService.getPinyinInitials(middleName)
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
