import Foundation
import Testing
@testable import Sodium_Tracker

@MainActor
struct NumericLocalizationTests {
    private func sodium(_ text: String, _ identifier: String, unit: SodiumInputUnit = .sodiumMilligrams) -> Int? {
        SodiumConverter.sodiumMilligrams(from: text, unit: unit, locale: Locale(identifier: identifier))
    }

    @Test func decimalCommaAndPointRemainSupported() {
        for locale in ["en_US", "de_DE", "fr_FR", "it_IT", "nl_NL"] {
            #expect(sodium("1.5", locale, unit: .saltGrams) == 590)
            #expect(sodium("1,5", locale, unit: .saltGrams) == 590)
            #expect(sodium("470.4", locale) == 470)
            #expect(sodium("470,4", locale) == 470)
        }
        #expect(sodium(".5", "en_US", unit: .saltGrams) == 197)
        #expect(sodium(",5", "de_DE", unit: .saltGrams) == 197)
    }

    @Test func groupingFollowsTheSelectedLocale() {
        #expect(sodium("1,234.5", "en_US") == 1235)
        #expect(sodium("1.234,5", "de_DE") == 1235)
        #expect(sodium("1.234,5", "it_IT") == 1235)
        #expect(sodium("1 234,5", "fr_FR") == 1235)
        #expect(sodium("1\u{00A0}234,5", "fr_FR") == 1235)
        #expect(sodium("1\u{202F}234,5", "fr_FR") == 1235)
        #expect(sodium("1’234.5", "de_CH") == 1235)
        #expect(sodium("1'234.5", "de_CH") == 1235)
        #expect(sodium("1,234,567", "en_US") == 1234567)
        #expect(sodium("12,34,567", "en_IN") == 1234567)
        // A valid grouping separator must not be reinterpreted as a decimal.
        #expect(sodium("1,500", "en_US") == 1500)
        #expect(sodium("1.500", "de_DE") == 1500)
        #expect(sodium("1,500", "de_DE", unit: .saltGrams) == 590)
    }

    @Test func localizedDigitsAreNotSilentlyDiscarded() {
        #expect(sodium("௧௨௩", "ta_IN") == 123)
        #expect(sodium("１２３", "ja_JP") == 123)
        #expect(sodium("١٢٣", "en_US") == 123)
        #expect(sodium("௧,௫", "ta_IN", unit: .saltGrams) == 590)
        #expect(sodium("½", "en_US", unit: .saltGrams) == nil)
        #expect(sodium("²", "en_US") == nil)
    }

    @Test func invalidPastedTextIsRejectedRatherThanChanged() {
        for value in ["", "0", "-10", "+10", "−10", "1e3", "NaN", "inf", "12mg", "1,2,3", "1..5", "1.5.2", "1\n234", "1\t234", "1,"] {
            #expect(sodium(value, "en_US") == nil, "Unexpected acceptance: \(value)")
        }
        #expect(sodium("1.234,5", "en_US") == nil)
        #expect(sodium("1,234.5", "de_DE") == nil)
        #expect(sodium("1 234", "en_US") == nil)
        #expect(sodium("12 34 567", "fr_FR") == nil)
        #expect(sodium("1,23,456", "en_US") == nil)
        #expect(sodium("1,234,567", "en_IN") == nil)
        #expect(sodium("  470\n", "en_US") == 470)
        #expect(sodium("1,2", "en_US") == 1) // Never the old input filter's 12 mg.
    }

    @Test func conversionAndOverflowChecksRemainUnchanged() {
        #expect(sodium("1", "en_US", unit: .saltGrams) == 393)
        #expect(sodium("1.234,5", "de_DE", unit: .saltGrams) == 485652)
        #expect(sodium("1,234.5", "en_US", unit: .saltGrams) == 485652)
        #expect(sodium(String(repeating: "9", count: 400), "en_US") == nil)
        #expect(sodium(String(Int.max), "en_US") == nil)
    }
}
