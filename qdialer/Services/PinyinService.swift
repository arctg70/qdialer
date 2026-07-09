import Foundation

// MARK: - Pinyin Conversion Service

final class PinyinService {
    nonisolated(unsafe) static let shared = PinyinService()

    private init() {}

    /// Convert Chinese text to pinyin with tones, then strip tone marks
    /// "张三" → "zhang san"
    func getPinyin(_ text: String) -> String {
        guard !text.isEmpty else { return "" }
        let mutable = NSMutableString(string: text) as CFMutableString

        guard CFStringTransform(mutable, nil, kCFStringTransformToLatin, false) else {
            return text.lowercased()
        }
        guard CFStringTransform(mutable, nil, kCFStringTransformStripCombiningMarks, false) else {
            return text.lowercased()
        }
        return (mutable as String).trimmingCharacters(in: .whitespaces).lowercased()
    }

    /// Get the first letter of each character's pinyin
    /// "张三" → "zs"
    /// "Hello 世界" → "hsj"
    func getPinyinInitials(_ text: String) -> String {
        let pinyin = getPinyin(text)
        guard !pinyin.isEmpty else { return "" }

        // Split by spaces (each Han character becomes one pinyin word)
        let words = pinyin.split(separator: " ")
        let initials = words.compactMap { $0.first.map { String($0).lowercased() } }.joined()
        return initials
    }

    /// Check if a search query matches the given contact name
    /// Returns the match score (higher = better match), or nil if no match
    func matchQuery(query: String, contact: ContactModel) -> Int? {
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return nil }

        var scores = [Int]()

        // === Direct name substring matching ===
        let name = contact.fullName.lowercased()
        if name == q { scores.append(10000) }
        else if name.hasPrefix(q) { scores.append(5000) }
        else if name.contains(q) { scores.append(2000) }

        // === Pinyin full matching ===
        let py = contact.pinyinFull
        let pyNoSpace = py.replacingOccurrences(of: " ", with: "")
        if py == q { scores.append(8000) }
        else if py.hasPrefix(q) || pyNoSpace.hasPrefix(q) { scores.append(4000) }
        else if py.contains(q) || pyNoSpace.contains(q) { scores.append(1500) }

        // === Pinyin initials matching ===
        let initials = contact.pinyinInitials
        let givenInitials = contact.givenNamePinyinInitials
        let familyInitials = contact.familyNamePinyinInitials

        if initials == q { scores.append(6000) }
        else if initials.hasPrefix(q) { scores.append(3000) }
        else if initials.contains(q) { scores.append(1000) }

        // Match against given name or family name initials separately
        if givenInitials == q || familyInitials == q { scores.append(4500) }
        else if givenInitials.hasPrefix(q) || familyInitials.hasPrefix(q) { scores.append(2000) }

        // === Reversed name (Chinese order "Zhang San") matching ===
        let revName = contact.reversedName.lowercased()
        if revName == q { scores.append(9500) }
        else if revName.hasPrefix(q) { scores.append(4500) }
        else if revName.contains(q) { scores.append(1800) }

        let revPy = contact.pinyinReversedFull
        let revPyNoSpace = revPy.replacingOccurrences(of: " ", with: "")
        if revPy == q { scores.append(7500) }
        else if revPy.hasPrefix(q) || revPyNoSpace.hasPrefix(q) { scores.append(3500) }
        else if revPy.contains(q) || revPyNoSpace.contains(q) { scores.append(1400) }

        let revInits = contact.pinyinReversedInitials
        if revInits == q { scores.append(5500) }
        else if revInits.hasPrefix(q) { scores.append(2500) }
        else if revInits.contains(q) { scores.append(900) }

        // === Nickname matching ===
        if !contact.nickname.isEmpty {
            let nick = contact.nickname.lowercased()
            if nick == q { scores.append(9000) }
            else if nick.hasPrefix(q) { scores.append(4500) }
            else if nick.contains(q) { scores.append(2000) }

            // Nickname pinyin
            let nickPy = contact.nicknamePinyin
            if nickPy == q { scores.append(7000) }
            else if nickPy.hasPrefix(q) || nickPy.contains(q) { scores.append(2500) }
        }

        // === Organization matching ===
        if !contact.organization.isEmpty {
            let orgName = contact.organization.lowercased()
            if orgName == q { scores.append(5000) }
            else if orgName.hasPrefix(q) { scores.append(3000) }
            else if orgName.contains(q) { scores.append(1200) }
        }
        if !contact.orgPinyin.isEmpty {
            let org = contact.orgPinyin
            if org == q { scores.append(4500) }
            else if org.hasPrefix(q) || org.contains(q) { scores.append(1000) }
        }
        if !contact.orgPinyinInitials.isEmpty {
            let orgInit = contact.orgPinyinInitials
            if orgInit == q { scores.append(4000) }
            else if orgInit.hasPrefix(q) { scores.append(2000) }
            else if orgInit.contains(q) { scores.append(800) }
        }

        // === Phone number matching ===
        for phone in contact.phoneNumbers {
            let digits = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            if digits == q { scores.append(7000) }
            else if digits.hasSuffix(q) { scores.append(3500) }
            else if digits.contains(q) { scores.append(1200) }
        }

        return scores.max()
    }
}
