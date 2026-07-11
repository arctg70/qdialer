import SwiftUI

// MARK: - Simple localization helper (Chinese / English)

enum L {
    /// Whether the system language is Chinese
    static var isZh: Bool {
        Locale.preferredLanguages.first?.hasPrefix("zh") == true
    }

    /// Returns a localized Text view (avoids re-localization by using verbatim)
    static func text(_ en: String, _ zh: String) -> Text {
        Text(verbatim: isZh ? zh : en)
    }

    /// Returns a localized raw string
    static func str(_ en: String, _ zh: String) -> String {
        isZh ? zh : en
    }

    /// Returns a localized formatted string  (e.g. L.str("Found %d", "找到 %d", count))
    static func str(_ en: String, _ zh: String, _ args: CVarArg...) -> String {
        String(format: isZh ? zh : en, arguments: args)
    }
}
