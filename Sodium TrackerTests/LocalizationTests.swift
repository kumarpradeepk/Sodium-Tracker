import Foundation
import Testing
@testable import Sodium_Tracker

@MainActor
struct LocalizationTests {
    @Test func languageMatchingKeepsLanguageSeparateFromCountry() {
        #expect(PinchLocalization.language(for: ["de-CH"]) == "de")
        #expect(PinchLocalization.language(for: ["fr-CA"]) == "fr")
        #expect(PinchLocalization.language(for: ["en-SG"]) == "en")
        #expect(PinchLocalization.language(for: ["zh-Hans-SG"]) == "zh-Hans")
        #expect(PinchLocalization.language(for: ["mi-NZ"]) == "mi")
        #expect(PinchLocalization.language(for: ["rm-CH"]) == "rm")
        #expect(PinchLocalization.language(for: ["ga-IE"]) == "ga")
        #expect(PinchLocalization.language(for: ["xx", "fr-CH"]) == "fr")
        #expect(PinchLocalization.language(for: ["en"], override: "ta") == "ta")
        #expect(PinchLocalization.language(for: ["de"], override: "system") == "de")
    }

    @Test func interpolationPreservesUserContentAndCurrency() {
        let name = "Mom’s {1} soup 💙"
        let value = PinchLocalization.format("{0}, {1} mg", [name, "2,300"], language: "en")
        #expect(value == "Mom’s {1} soup 💙, 2,300 mg")
        #expect(PinchLocalization.format("Subscribe for {0}/{1}", ["CHF 29.99", "year"], language: "en") == "Subscribe for CHF 29.99/year")
        #expect(PinchLocalization.resolve("My unchanged food 🥣", language: "ja") == "My unchanged food 🥣")
    }

    @Test func customFoodIsNeverMistakenForInterfaceCopy() {
        let food = FoodItem(id: "user-localization-test", name: "Today", serving: "Breakfast", mg: 42, category: .custom)
        #expect(food.displayName == "Today")
        #expect(food.displayServing == "Breakfast")
    }

    @Test func generatedPortionsAndMissingSourcesAreLocalizedWithoutTranslatingUserFood() {
        let old = UserDefaults.standard.string(forKey: PinchLocalization.preferenceKey)
        UserDefaults.standard.set("de", forKey: PinchLocalization.preferenceKey)
        defer {
            if let old { UserDefaults.standard.set(old, forKey: PinchLocalization.preferenceKey) }
            else { UserDefaults.standard.removeObject(forKey: PinchLocalization.preferenceKey) }
        }
        let food = CustomFood(name: "Today", serving: "1 serving", mg: 42, usesDefaultServing: true)
        let entry = LogEntry(foodID: food.id, meal: .lunch)
        let resolved = EntryResolver.resolve(entry, customFoods: [food])
        #expect(resolved.displayName == "Today")
        #expect(resolved.displayServing == PinchLocalization.resolve("1 serving"))
        let manual = FoodItem(id: "manual", name: "Unknown", serving: "Breakfast", mg: 42, category: .custom)
        #expect(manual.displayName == "Unknown")
        #expect(manual.displayServing == "Breakfast")
        let missing = EntryResolver.resolve(LogEntry(foodID: "deleted", meal: .lunch), customFoods: [])
        #expect(missing.displayName == PinchLocalization.resolve("Unknown"))
        let builtIn = EntryResolver.resolve(LogEntry(foodID: "sour", meal: .breakfast), customFoods: [])
        #expect(builtIn.displayServing == PinchLocalization.resolve("1 slice"))
        let copy = FoodRecommendations.entry(for: food.asFoodItem, loggedAt: .now)
        #expect(EntryResolver.resolve(copy, customFoods: []).displayServing == PinchLocalization.resolve("1 serving"))
    }

    @Test func calendarWeekdaysRespectRegionalFirstDay() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
        let sunday = try #require(calendar.date(from: DateComponents(year: 2026, month: 9, day: 6)))
        calendar.firstWeekday = 1
        let sundaySymbols = PinchFormat.weekdaySymbols(calendar: calendar)
        #expect(PinchFormat.weekdayColumn(for: sunday, calendar: calendar) == 0)
        calendar.firstWeekday = 2
        let mondaySymbols = PinchFormat.weekdaySymbols(calendar: calendar)
        #expect(PinchFormat.weekdayColumn(for: sunday, calendar: calendar) == 6)
        #expect(mondaySymbols == Array(sundaySymbols.dropFirst()) + [sundaySymbols[0]])
    }

    @Test func allRequestedLanguagesHaveCompleteBundledCatalogs() throws {
        let url = try #require(Bundle.main.url(forResource: "PinchStrings", withExtension: "json"))
        let catalogs = try JSONDecoder().decode([String: [String: String]].self, from: Data(contentsOf: url))
        let english = try #require(catalogs["en"])
        #expect(english.count > 450)
        #expect(PinchLocalization.supportedLanguages.count == 14)
        let pattern = try NSRegularExpression(pattern: #"\{\d+\}"#)
        func tokens(_ value: String) -> [String] {
            let text = value as NSString
            return pattern.matches(in: value, range: NSRange(location: 0, length: text.length))
                .map { text.substring(with: $0.range) }.sorted()
        }
        for language in PinchLocalization.supportedLanguages {
            let translated = try #require(catalogs[language], "Missing catalog: \(language)")
            #expect(Set(translated.keys) == Set(english.keys), "Incomplete catalog: \(language)")
            for (key, value) in translated {
                #expect(!value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                #expect(tokens(key) == tokens(value), "Placeholder mismatch: \(language): \(key)")
                #expect(!value.contains("ZXQ"), "Draft translation marker leaked")
            }
        }
    }
}
