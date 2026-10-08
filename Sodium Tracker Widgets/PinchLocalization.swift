import Foundation

/// App-owned interface copy only. User-entered foods and remote provider text
/// remain verbatim. Templates are translated before values are interpolated.
enum PinchLocalization {
    static let preferenceKey = "pinch.language"
    static let appGroup = "group.com.kabi.sodium.tracker"
    static let supportedLanguages = ["en", "de", "ja", "fr", "nl", "it", "es", "sv", "zh-Hans", "ms", "ta", "ga", "mi", "rm"]
    static let languageNames = [
        "en": "English", "de": "Deutsch", "ja": "日本語", "fr": "Français",
        "nl": "Nederlands", "it": "Italiano", "es": "Español", "sv": "Svenska",
        "zh-Hans": "简体中文", "ms": "Bahasa Melayu", "ta": "தமிழ்",
        "ga": "Gaeilge", "mi": "Māori", "rm": "Rumantsch"
    ]

    static func language(for preferences: [String], override: String? = nil) -> String {
        if let override, supportedLanguages.contains(override) { return override }
        for identifier in preferences {
            let parts = identifier.replacingOccurrences(of: "_", with: "-").lowercased().split(separator: "-")
            guard let base = parts.first else { continue }
            let match = base == "zh" ? "zh-Hans" : String(base)
            if supportedLanguages.contains(match) { return match }
        }
        return "en"
    }

    static var currentLanguage: String {
        let local = UserDefaults.standard.string(forKey: preferenceKey)
        let shared = UserDefaults(suiteName: appGroup)?.string(forKey: preferenceKey)
        return language(for: Locale.preferredLanguages, override: local ?? shared)
    }

    static var locale: Locale {
        // Language and region are independent: retain the user's date/number region.
        Locale(identifier: currentLanguage + "_" + (Locale.current.region?.identifier ?? "US"))
    }

    private static let catalogs: [String: [String: String]] = {
        guard let url = Bundle.main.url(forResource: "PinchStrings", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: [String: String]].self, from: data) else {
            assertionFailure("PinchStrings.json missing from application bundle")
            return [:]
        }
        return decoded
    }()

    static func resolve(_ key: String) -> String { resolve(key, language: currentLanguage) }

    // Do not silently advertise partial catalogs after a resource regression.
    static var availableLanguages: [String] {
        let keys = Set(catalogs["en"]?.keys.map { $0 } ?? [])
        return supportedLanguages.filter { language in
            guard !keys.isEmpty, let dictionary = catalogs[language] else { return false }
            return Set(dictionary.keys) == keys && dictionary.values.allSatisfy { !$0.isEmpty }
        }
    }

    static func resolve(_ key: String, language: String) -> String {
        let normalized = self.language(for: [language])
        return catalogs[normalized]?[key] ?? key
    }

    static func format(_ key: String, _ arguments: [String], language: String? = nil) -> String {
        let template = resolve(key, language: language ?? currentLanguage)
        // A single pass prevents braces in a food name from becoming placeholders.
        let regex = try! NSRegularExpression(pattern: #"\{(\d+)\}"#)
        let original = template as NSString
        let matches = regex.matches(in: template, range: NSRange(location: 0, length: original.length))
        var result = template
        for match in matches.reversed() {
            guard let index = Int(original.substring(with: match.range(at: 1))),
                  arguments.indices.contains(index),
                  let range = Range(match.range, in: result) else { continue }
            result.replaceSubrange(range, with: arguments[index])
        }
        return result
    }

    static func number(_ value: Int) -> String {
        value.formatted(.number.locale(locale))
    }
}
