//
//  Sodium_TrackerTests.swift
//  Sodium TrackerTests
//
//  Created by pradeep.kumar1 on 01/08/26.
//

import Testing
import Foundation
import SwiftUI
@testable import Sodium_Tracker

struct PremiumPolicyTests {
    @Test func freeTierAndPlusContract() {
        #expect(!PremiumAccessPolicy.allows(.monthTrends, isPremium: false))
        #expect(!PremiumAccessPolicy.allows(.historyCalendar, isPremium: false))
        #expect(!PremiumAccessPolicy.allows(.csvExport, isPremium: false))
        #expect(!PremiumAccessPolicy.allows(.remoteFoodLogging, isPremium: false))
        #expect(!PremiumAccessPolicy.allows(.barcodeScanner, isPremium: false))
        #expect(!PremiumAccessPolicy.allows(.widgets, isPremium: false))
        #expect(PremiumAccessPolicy.allows(.unlimitedCustomFoods, isPremium: false, customFoodCount: 2))
        #expect(!PremiumAccessPolicy.allows(.unlimitedCustomFoods, isPremium: false, customFoodCount: 3))
        #expect(PremiumAccessPolicy.allows(.widgets, isPremium: true))
        #expect(PremiumAccessPolicy.allows(.unlimitedCustomFoods, isPremium: true, customFoodCount: 500))
    }
}

struct LocalizationParityTests {
    @Test func resolvesLiteralAndRuntimeCopy() {
        #expect(PinchLocalization.resolve("Today", language: "de") == "Heute")
        #expect(PinchLocalization.resolve("Today", language: "ja") == "今日")
        #expect(PinchLocalization.resolve("3-day streak", language: "de") == "3-Tage-Serie")
        #expect(PinchLocalization.resolve("500 mg left", language: "ja") == "残り 500 mg")
        #expect(PinchLocalization.resolve("Today", language: "en") == "Today")
    }
}

struct SodiumConverterTests {
    @Test func keepsSodiumMilligrams() {
        #expect(SodiumConverter.sodiumMilligrams("470", unit: .sodiumMilligrams) == 470)
    }

    @Test func convertsSaltGramsAndLocalizedDecimal() {
        #expect(SodiumConverter.sodiumMilligrams("1", unit: .saltGrams) == 393)
        #expect(SodiumConverter.sodiumMilligrams("2,5", unit: .saltGrams) == 984)
    }

    @Test func rejectsMissingAndInvalidAmounts() {
        #expect(SodiumConverter.sodiumMilligrams("", unit: .sodiumMilligrams) == nil)
        #expect(SodiumConverter.sodiumMilligrams("-2", unit: .saltGrams) == nil)
        #expect(SodiumConverter.sodiumMilligrams("NaN", unit: .sodiumMilligrams) == nil)
    }
}

// MARK: - Palettes (v2: Ocean / Sage / Iris, light + dark)

struct PaletteTests {
    @Test func resolveReturnsRequestedFamilyAndTheme() {
        for pick in PalettePick.allCases {
            let light = PinchPalette.resolve(pick, dark: false)
            let dark = PinchPalette.resolve(pick, dark: true)
            #expect(!light.isDark)
            #expect(dark.isDark)
            #expect(light.brand != dark.brand, "\(pick.rawValue) light/dark must differ")
        }
    }

    @Test func brandTokensMatchDesign() {
        #expect(PinchPalette.resolve(.ocean, dark: false).brand == Color(hex: 0x2E6FBD))
        #expect(PinchPalette.resolve(.ocean, dark: true).brand == Color(hex: 0x5CB3E8))
        #expect(PinchPalette.resolve(.sage, dark: false).brand == Color(hex: 0x35705A))
        #expect(PinchPalette.resolve(.sage, dark: true).brand == Color(hex: 0x8CC3A6))
        #expect(PinchPalette.resolve(.iris, dark: false).brand == Color(hex: 0x5A52C4))
        #expect(PinchPalette.resolve(.iris, dark: true).brand == Color(hex: 0xA29BEE))
    }

    @Test func fallbackIsOceanLight() {
        #expect(PinchPalette.fallback == PinchPalette.oceanLight)
    }

    @Test func scanAccentsAreSharedAcrossThemesOfAFamily() {
        for pick in PalettePick.allCases {
            let light = PinchPalette.resolve(pick, dark: false)
            let dark = PinchPalette.resolve(pick, dark: true)
            #expect(light.scanAcc == dark.scanAcc)
            #expect(light.scanInk == dark.scanInk)
        }
    }

    @Test func ringGlowIsFixedPerFamily() {
        for pick in PalettePick.allCases {
            let light = PinchPalette.resolve(pick, dark: false)
            let dark = PinchPalette.resolve(pick, dark: true)
            #expect(light.ringGlow(pct: 10) == dark.ringGlow(pct: 10))
            #expect(light.ringGlow(pct: 85) == dark.ringGlow(pct: 85))
            #expect(light.ringGlow(pct: 120) == dark.ringGlow(pct: 120))
        }
    }

    @Test func barFillsPickTheRightGradient() {
        let p = PinchPalette.oceanLight
        #expect(p.barFill(over: false, live: true) == p.barNow)
        #expect(p.barFill(over: true, live: true) == p.barNowOver)
        #expect(p.barFill(over: false, live: false) == p.barUnder)
        #expect(p.barFill(over: true, live: false) == p.barOver)
    }
}

// MARK: - Tone & mood thresholds (design's sodium tone scale)

struct ToneScaleTests {
    let palette = PinchPalette.resolve(.ocean, dark: false)

    @Test func toneBands() {
        #expect(palette.tone(0) == palette.brand)
        #expect(palette.tone(299) == palette.brand)
        #expect(palette.tone(300) == palette.amber)
        #expect(palette.tone(699) == palette.amber)
        #expect(palette.tone(700) == palette.coral)
        #expect(palette.tone(1560) == palette.coral)
    }

    @Test func ringZones() {
        #expect(palette.ringColor(pct: 0) == palette.brand)
        #expect(palette.ringColor(pct: 77.9) == palette.brand)
        #expect(palette.ringColor(pct: 78) == palette.amber)
        #expect(palette.ringColor(pct: 99.9) == palette.amber)
        #expect(palette.ringColor(pct: 100) == palette.coral)
    }

    @Test func moodThresholds() {
        #expect(Mood.forPercent(0) == .fresh)
        #expect(Mood.forPercent(39.9) == .fresh)
        #expect(Mood.forPercent(40) == .ok)
        #expect(Mood.forPercent(77.9) == .ok)
        #expect(Mood.forPercent(78) == .wary)
        #expect(Mood.forPercent(99.9) == .wary)
        #expect(Mood.forPercent(100) == .over)
        #expect(Mood.forPercent(180) == .over)
    }

    @Test func moodExtras() {
        #expect(Mood.fresh.showsSparkles)
        #expect(!Mood.ok.showsSparkles)
        #expect(Mood.wary.showsSweat)
        #expect(Mood.over.showsSweat)
        #expect(!Mood.fresh.showsSweat)
        #expect(Mood.fresh.browOpacity == 0)
        #expect(Mood.over.browOpacity == 1)
    }

    @Test func toastCopyBySize() {
        #expect(ToastCopy.line(forAdded: 100) == "Light touch. Nice pick.")
        #expect(ToastCopy.line(forAdded: 300).hasPrefix("Noted"))
        #expect(ToastCopy.line(forAdded: 700).hasPrefix("Whew"))
    }
}

// MARK: - Meals

struct MealTests {
    @Test func autoMealByHour() {
        #expect(Meal.auto(hour: 0) == .breakfast)
        #expect(Meal.auto(hour: 10) == .breakfast)
        #expect(Meal.auto(hour: 11) == .lunch)
        #expect(Meal.auto(hour: 14) == .lunch)
        #expect(Meal.auto(hour: 15) == .dinner)
        #expect(Meal.auto(hour: 20) == .dinner)
        #expect(Meal.auto(hour: 21) == .snacks)
        #expect(Meal.auto(hour: 23) == .snacks)
    }
}

// MARK: - Formatting

struct FormatTests {
    @Test func groupedMilligrams() {
        #expect(PinchFormat.mg(2300) == "2,300")
        #expect(PinchFormat.mg(967) == "967")
        #expect(PinchFormat.mg(0) == "0")
        #expect(PinchFormat.mg(1560.4) == "1,560")
    }

    @Test func servingFractions() {
        #expect(PinchFormat.servings(0.5) == "½")
        #expect(PinchFormat.servings(1) == "1")
        #expect(PinchFormat.servings(1.5) == "1½")
        #expect(PinchFormat.servings(2) == "2")
        #expect(PinchFormat.servings(2.5) == "2½")
        #expect(PinchFormat.servings(3.5) == "3½")
        #expect(PinchFormat.servings(4) == "4")
    }

    @Test func thousandsLabel() {
        #expect(PinchFormat.thousands(1980) == "2.0k")
        #expect(PinchFormat.thousands(1320) == "1.3k")
        #expect(PinchFormat.thousands(0) == "0.0k")
    }
}

// MARK: - Goal

struct GoalTests {
    @Test func goalChoices() {
        #expect(GoalChoice.aha.milligrams(custom: 9999) == 1500)
        #expect(GoalChoice.fda.milligrams(custom: 9999) == 2300)
        #expect(GoalChoice.custom.milligrams(custom: 2000) == 2000)
    }

    @Test func customGoalUsesPrototypeBoundsAndStep() {
        #expect(PinchDefaults.customGoalRange == 800...3000)
        #expect(PinchDefaults.customGoalStep == 100)
    }
}

struct PremiumPolicyTests {
    @Test func widgetsArePlusOnly() {
        #expect(!PremiumAccessPolicy.allows(.widgets, isPremium: false))
        #expect(PremiumAccessPolicy.allows(.widgets, isPremium: true))
    }
}

// MARK: - Label conversion

struct SodiumConverterTests {
    @Test func keepsSodiumMilligramsAsEntered() {
        #expect(SodiumConverter.sodiumMilligrams(from: "470", unit: .sodiumMilligrams) == 470)
        #expect(SodiumConverter.sodiumMilligrams(from: "470.4", unit: .sodiumMilligrams) == 470)
    }

    @Test func convertsSaltGramsToSodiumMilligrams() {
        #expect(SodiumConverter.sodiumMilligrams(from: "1", unit: .saltGrams) == 393)
        #expect(SodiumConverter.sodiumMilligrams(from: "1.5", unit: .saltGrams) == 590)
        #expect(SodiumConverter.sodiumMilligrams(from: "1,5", unit: .saltGrams) == 590)
    }

    @Test func rejectsInvalidOrNonPositiveInput() {
        #expect(SodiumConverter.sodiumMilligrams(from: "", unit: .saltGrams) == nil)
        #expect(SodiumConverter.sodiumMilligrams(from: "0", unit: .saltGrams) == nil)
        #expect(SodiumConverter.sodiumMilligrams(from: "nope", unit: .sodiumMilligrams) == nil)
    }
}

// MARK: - Premium access

struct PremiumAccessPolicyTests {
    @Test func paidEntitlementUnlocksEveryPremiumFeature() {
        for feature in PremiumFeature.allCases {
            #expect(PremiumAccessPolicy.allows(feature, isPremium: true, customFoodCount: 999))
        }
    }

    @Test func freeTierCannotUseTrendsOrExport() {
        #expect(!PremiumAccessPolicy.allows(.monthTrends, isPremium: false))
        #expect(!PremiumAccessPolicy.allows(.historyCalendar, isPremium: false))
        #expect(!PremiumAccessPolicy.allows(.csvExport, isPremium: false))
        #expect(!PremiumAccessPolicy.allows(.remoteFoodLogging, isPremium: false))
        #expect(!PremiumAccessPolicy.allows(.barcodeScanner, isPremium: false))
    }

    @Test func freeShelfHasAnEnforcedLimit() {
        let limit = PremiumAccessPolicy.freeCustomFoodLimit
        #expect(PremiumAccessPolicy.allows(.unlimitedCustomFoods, isPremium: false, customFoodCount: limit - 1))
        #expect(!PremiumAccessPolicy.allows(.unlimitedCustomFoods, isPremium: false, customFoodCount: limit))
    }
}

// MARK: - Day engine

@MainActor
struct DayEngineTests {
    private func entry(_ foodID: String, servings: Double = 1, meal: Meal = .lunch, dayOffset: Int) -> LogEntry {
        LogEntry(
            foodID: foodID,
            servings: servings,
            meal: meal,
            loggedAt: DayEngine.day(offset: dayOffset).addingTimeInterval(12 * 3600)
        )
    }

    @Test func dayTotalsMultiplyServings() {
        let entries = [
            entry("yog", dayOffset: 0),            // 65
            entry("ram", servings: 1.5, dayOffset: 0),  // 2340
            entry("eda", dayOffset: 0),            // 220
            entry("piz", dayOffset: -1),           // different day
        ]
        let total = DayEngine.total(entries, on: .now, customFoods: [])
        #expect(total == 65 + 2340 + 220)
    }

    @Test func adhocEntriesResolve() {
        let quick = LogEntry(adhocName: "Diner omelette", adhocMg: 640, servings: 1, meal: .breakfast)
        let resolved = EntryResolver.resolve(quick, customFoods: [])
        #expect(resolved.name == "Diner omelette")
        #expect(resolved.baseMg == 640)
        #expect(resolved.serving == "quick log")
        #expect(resolved.totalMg == 640)
    }

    @Test func adhocEntriesCarryTheirServingLabel() {
        // FatSecret-sourced entries keep the API's portion description.
        let remote = LogEntry(
            adhocName: "Campbell's Chicken Noodle",
            adhocMg: 870,
            adhocServing: "1 cup",
            servings: 1.5,
            meal: .lunch
        )
        let resolved = EntryResolver.resolve(remote, customFoods: [])
        #expect(resolved.serving == "1 cup")
        #expect(resolved.totalMg == 1305)
    }

    @Test func customFoodsResolve() {
        let soup = CustomFood(id: "cf1", name: "Nana's lentil soup", serving: "1 bowl", mg: 410)
        let logged = LogEntry(foodID: "cf1", servings: 2, meal: .dinner)
        let resolved = EntryResolver.resolve(logged, customFoods: [soup])
        #expect(resolved.name == "Nana's lentil soup")
        #expect(resolved.totalMg == 820)
        #expect(resolved.category == .custom)
    }

    @Test func streakCountsConsecutiveDays() {
        var entries: [LogEntry] = []
        for offset in [-4, -3, -2, -1, 0] {
            entries.append(entry("yog", dayOffset: offset))
        }
        #expect(DayEngine.streak(entries) == 5)
    }

    @Test func streakSurvivesQuietToday() {
        var entries: [LogEntry] = []
        for offset in [-3, -2, -1] {
            entries.append(entry("yog", dayOffset: offset))
        }
        #expect(DayEngine.streak(entries) == 3)
    }

    @Test func streakBreaksOnGap() {
        let entries = [
            entry("yog", dayOffset: 0),
            entry("yog", dayOffset: -1),
            entry("yog", dayOffset: -3),  // gap at -2
        ]
        #expect(DayEngine.streak(entries) == 2)
    }

    @Test func emptyLogHasNoStreak() {
        #expect(DayEngine.streak([]) == 0)
    }

    @Test func weekStatsCountUnderBudget() {
        var entries: [LogEntry] = []
        for offset in -6...0 {
            entries.append(entry("ram", dayOffset: offset))  // 1,560 each day
        }
        let week = DayEngine.week(entries, customFoods: [], goal: 2300)
        #expect(week.dayTotals.count == 7)
        #expect(week.underCount == 7)
        #expect(abs(week.average - 1560) < 0.001)

        let strict = DayEngine.week(entries, customFoods: [], goal: 1500)
        #expect(strict.underCount == 0)
    }

    @Test func lightestDayExcludesToday() {
        var entries: [LogEntry] = [
            entry("ban", dayOffset: 0)  // 1 mg today — but today is excluded
        ]
        for offset in -6...(-1) {
            entries.append(entry(offset == -3 ? "chick" : "burg", dayOffset: offset))
        }
        let week = DayEngine.week(entries, customFoods: [], goal: 2300)
        let lightest = week.lightestDate
        #expect(lightest != nil)
        if let lightest {
            #expect(Calendar.current.isDate(lightest, inSameDayAs: DayEngine.day(offset: -3)))
        }
    }

    @Test func weekDeltaPercent() {
        #expect(DayEngine.weekDelta(thisAvg: 1885, lastAvg: 2071) == -9)
        #expect(DayEngine.weekDelta(thisAvg: 2071, lastAvg: 1885) == 10)
        #expect(DayEngine.weekDelta(thisAvg: 1000, lastAvg: 0) == nil)
    }
}

// MARK: - Search

struct SearchTests {
    @Test func prefixMatchesRankFirst() {
        let hits = DayEngine.search("s", builtIn: FoodItem.catalog, custom: [])
        #expect(!hits.isEmpty)
        let firstNonPrefixIndex = hits.firstIndex { !$0.name.lowercased().hasPrefix("s") }
        if let firstNonPrefixIndex {
            // Every prefix match must come before every non-prefix match.
            for i in firstNonPrefixIndex..<hits.count {
                #expect(!hits[i].name.lowercased().hasPrefix("s"))
            }
        }
    }

    @Test func sortsByMgDescendingWithinRank() {
        let hits = DayEngine.search("so", builtIn: FoodItem.catalog, custom: [])
        let prefix = hits.filter { $0.name.lowercased().hasPrefix("so") }
        let sorted = prefix.map(\.mg)
        #expect(sorted == sorted.sorted(by: >))
    }

    @Test func findsCustomFoods() {
        let custom = CustomFood(id: "cf1", name: "Nana's lentil soup", serving: "1 bowl", mg: 410)
        let hits = DayEngine.search("lentil", builtIn: FoodItem.catalog, custom: [custom])
        #expect(hits.count == 1)
        #expect(hits.first?.id == "cf1")
    }

    @Test func emptyQueryReturnsNothing() {
        #expect(DayEngine.search("", builtIn: FoodItem.catalog, custom: []).isEmpty)
        #expect(DayEngine.search("   ", builtIn: FoodItem.catalog, custom: []).isEmpty)
    }

    @Test func unmatchedQueryReturnsNothing() {
        #expect(DayEngine.search("zzz-not-a-food", builtIn: FoodItem.catalog, custom: []).isEmpty)
    }

    @Test func shelfBandsSplitAtDesignBoundaries() {
        let bands = DayEngine.shelfBands(FoodItem.catalog)
        #expect(bands.count == 3)
        #expect(bands[0].rows.allSatisfy { $0.mg >= 800 })
        #expect(bands[1].rows.allSatisfy { $0.mg >= 300 && $0.mg < 800 })
        #expect(bands[2].rows.allSatisfy { $0.mg < 300 })
        // Highest first inside each band
        for band in bands {
            let mgs = band.rows.map(\.mg)
            #expect(mgs == mgs.sorted(by: >))
        }
        // Every catalog item lands in exactly one band
        #expect(bands.reduce(0) { $0 + $1.rows.count } == FoodItem.catalog.count)
    }
}

// MARK: - Catalog integrity

struct CatalogTests {
    @Test func catalogMatchesDesign() {
        #expect(FoodItem.catalog.count == 32)
        #expect(FoodItem.builtIn("ram")?.mg == 1560)
        #expect(FoodItem.builtIn("yog")?.mg == 65)
        #expect(FoodItem.builtIn("soup")?.mg == 870)
        #expect(FoodItem.builtIn("ban")?.mg == 1)
    }

    @Test func everyItemIsSane() {
        for item in FoodItem.catalog {
            #expect(item.mg > 0, "\(item.name) has non-positive sodium")
            #expect(!item.name.isEmpty)
            #expect(!item.serving.isEmpty)
        }
        let ids = FoodItem.catalog.map(\.id)
        #expect(Set(ids).count == ids.count, "duplicate food ids")
    }

    @Test func usualSuspectsExist() {
        for id in UsualSuspects.ids {
            #expect(FoodItem.builtIn(id) != nil, "quick chip \(id) missing from catalog")
        }
    }

    @Test func categoryIconsParse() {
        for category in FoodCategory.allCases {
            let path = SVGPath.path(category.iconPath)
            #expect(!path.isEmpty, "\(category.rawValue) icon failed to parse")
        }
    }
}

// MARK: - Badges

@MainActor
struct BadgeTests {
    private func entriesForStreak(_ days: Int) -> [LogEntry] {
        (0..<days).map { i in
            LogEntry(
                foodID: "yog",
                servings: 1,
                meal: .breakfast,
                loggedAt: DayEngine.day(offset: -i).addingTimeInterval(9 * 3600)
            )
        }
    }

    @Test func streakBadgesUnlockInOrder() {
        let badges = BadgeEngine.badges(
            entries: entriesForStreak(14),
            customFoods: [],
            lookupCount: 25,
            sleuthEarnedAt: .now,
            streak: 14
        )
        let byID = Dictionary(uniqueKeysWithValues: badges.map { ($0.id, $0) })
        #expect(byID["first"]?.earned == true)
        #expect(byID["hat"]?.earned == true)
        #expect(byID["week"]?.earned == true)
        #expect(byID["sleuth"]?.earned == true)
        #expect(byID["steady"]?.earned == false)
        #expect(byID["steady"]?.progressNote == "16 to go")
    }

    @Test func hatTrickEarnDateIsThirdDayOfStreak() {
        let entries = entriesForStreak(5)  // started 4 days ago
        let badges = BadgeEngine.badges(
            entries: entries, customFoods: [],
            lookupCount: 0, sleuthEarnedAt: nil, streak: 5
        )
        let hat = badges.first { $0.id == "hat" }
        let expected = DayEngine.day(offset: -2)  // start(-4) + 2
        #expect(hat?.earnedDate.map { Calendar.current.isDate($0, inSameDayAs: expected) } == true)
    }

    @Test func coolCucumberCountsLightDays() {
        // 3 light days (yog 65), 2 heavy (ram 1560 → still under 1500? no: 1560 > 1500)
        var entries: [LogEntry] = []
        for offset in [0, -1, -2] {
            entries.append(LogEntry(foodID: "yog", servings: 1, meal: .breakfast,
                                    loggedAt: DayEngine.day(offset: offset).addingTimeInterval(9 * 3600)))
        }
        for offset in [-3, -4] {
            entries.append(LogEntry(foodID: "ram", servings: 1, meal: .lunch,
                                    loggedAt: DayEngine.day(offset: offset).addingTimeInterval(13 * 3600)))
        }
        let badges = BadgeEngine.badges(
            entries: entries, customFoods: [],
            lookupCount: 0, sleuthEarnedAt: nil, streak: 5
        )
        let cool = badges.first { $0.id == "cool" }
        #expect(cool?.earned == false)
        #expect(cool?.progressNote == "3 of 5 so far")
    }

    @Test func sleuthProgressCapsAt25() {
        let badges = BadgeEngine.badges(
            entries: [], customFoods: [],
            lookupCount: 7, sleuthEarnedAt: nil, streak: 0
        )
        let sleuth = badges.first { $0.id == "sleuth" }
        #expect(sleuth?.earned == false)
        #expect(sleuth?.progressNote == "7 of 25 so far")
    }
}

// MARK: - CSV export

@MainActor
struct CSVTests {
    @Test func csvHasHeaderAndRows() {
        let entries = [
            LogEntry(foodID: "yog", servings: 1, meal: .breakfast,
                     loggedAt: DayEngine.day(offset: 0).addingTimeInterval(8 * 3600)),
            LogEntry(adhocName: "Food, with comma", adhocMg: 300, servings: 1, meal: .lunch,
                     loggedAt: DayEngine.day(offset: 0).addingTimeInterval(13 * 3600)),
        ]
        let csv = CSVExporter.csv(entries: entries, customFoods: [])
        let lines = csv.split(separator: "\n")
        #expect(lines.count == 3)
        #expect(lines[0] == "date,time,meal,food,portion,servings,mg")
        #expect(lines[1].contains("Greek yogurt"))
        #expect(lines[2].contains("\"Food, with comma\""))
        #expect(lines[2].hasSuffix("300"))
    }
}

// MARK: - FatSecret parsing

struct FatSecretParserTests {
    @Test func parsesSearchResultArray() throws {
        let json = """
        {"foods":{"food":[
            {"food_id":"33691","food_name":"Chicken Noodle Soup","brand_name":"Campbell's",
             "food_description":"Per 1 cup - Calories: 60kcal | Fat: 1.50g"},
            {"food_id":"35718","food_name":"Ramen Noodles",
             "food_description":"Per 100g - Calories: 436kcal | Fat: 17.6g"}
        ],"max_results":"20","total_results":"2","page_number":"0"}}
        """
        let hits = try FatSecretParser.searchResults(from: Data(json.utf8))
        #expect(hits.count == 2)
        #expect(hits[0].id == "33691")
        #expect(hits[0].brand == "Campbell's")
        #expect(hits[0].subtitle == "Campbell's")
        #expect(hits[1].brand == nil)
        #expect(hits[1].subtitle == "Per 100g")
    }

    @Test func parsesSingleObjectQuirk() throws {
        // FatSecret returns a lone object (not a 1-element array) for single hits.
        let json = """
        {"foods":{"food":{"food_id":"99","food_name":"Miso Soup",
            "food_description":"Per 1 cup - Calories: 84kcal"},"total_results":"1"}}
        """
        let hits = try FatSecretParser.searchResults(from: Data(json.utf8))
        #expect(hits.count == 1)
        #expect(hits[0].name == "Miso Soup")
    }

    @Test func emptyResultsAreNotAnError() throws {
        let json = #"{"foods":{"max_results":"20","total_results":"0","page_number":"0"}}"#
        let hits = try FatSecretParser.searchResults(from: Data(json.utf8))
        #expect(hits.isEmpty)
    }

    @Test func parsesDetailWithStringNumbers() throws {
        let json = """
        {"food":{"food_id":"33691","food_name":"Chicken Noodle Soup",
         "servings":{"serving":[
            {"serving_description":"1 cup","calories":"60","sodium":"870"},
            {"serving_description":"100 g","calories":"25","sodium":"363"}
        ]}}}
        """
        let detail = try FatSecretParser.foodDetail(from: Data(json.utf8))
        #expect(detail.name == "Chicken Noodle Soup")
        #expect(detail.serving == "1 cup")
        #expect(detail.sodiumMg == 870)
        #expect(detail.calories == 60)
    }

    @Test func detailSkipsServingsWithoutSodium() throws {
        let json = """
        {"food":{"food_name":"Mystery Snack","servings":{"serving":[
            {"serving_description":"1 bag","calories":"150"},
            {"serving_description":"100 g","sodium":"492.5"}
        ]}}}
        """
        let detail = try FatSecretParser.foodDetail(from: Data(json.utf8))
        #expect(detail.serving == "100 g")
        #expect(detail.sodiumMg == 493)
    }

    @Test func detailWithNoSodiumThrows() {
        let json = """
        {"food":{"food_name":"Water","servings":{"serving":
            {"serving_description":"1 glass","calories":"0"}}}}
        """
        #expect(throws: FatSecretError.self) {
            _ = try FatSecretParser.foodDetail(from: Data(json.utf8))
        }
    }

    @Test func numberCoercionHandlesStringsAndDoubles() {
        #expect(FatSecretParser.number("870") == 870)
        #expect(FatSecretParser.number(12.5) == 12.5)
        #expect(FatSecretParser.number("abc") == nil)
        #expect(FatSecretParser.number(nil) == nil)
    }

    @Test func parsesTheRestrictedProxyContract() throws {
        let search = #"{"foods":[{"id":"33691","name":"Chicken Noodle Soup","brand":"Pinch Kitchen","summary":"Per 1 cup"}]}"#
        let hits = try FatSecretProxyParser.searchResults(from: Data(search.utf8))
        #expect(hits == [RemoteFood(id: "33691", name: "Chicken Noodle Soup", brand: "Pinch Kitchen", summary: "Per 1 cup")])

        let detail = #"{"name":"Chicken Noodle Soup","serving":"1 cup","sodiumMg":870,"calories":60}"#
        #expect(try FatSecretProxyParser.foodDetail(from: Data(detail.utf8))
            == RemoteFoodDetail(name: "Chicken Noodle Soup", serving: "1 cup", sodiumMg: 870, calories: 60))
    }
}

// MARK: - SVG parser

struct SVGParserTests {
    @Test func parsesBasicCommands() {
        let path = SVGPath.path("M0 0 L10 0 L10 10 Z")
        #expect(!path.isEmpty)
        let bounds = path.boundingRect
        #expect(abs(bounds.width - 10) < 0.001)
        #expect(abs(bounds.height - 10) < 0.001)
    }

    @Test func parsesCurvesAndArcs() {
        // The Label Sleuth magnifier: two arcs forming a circle + handle.
        let path = SVGPath.path("M13 13 L17 17 M4 9 A5 5 0 1 0 14 9 A5 5 0 1 0 4 9")
        #expect(!path.isEmpty)
        let bounds = path.boundingRect
        // Circle spans x 4...14, y 4...14; handle extends to 17.
        #expect(bounds.maxX > 16.5)
        #expect(bounds.minX < 4.5)
    }

    @Test func parsesMascotBody() {
        let body = SVGPath.path("M35 50 C35 45 42 43 60 43 C78 43 85 45 85 50 L87.5 95 C88.5 111 76 121 60 121 C44 121 32.5 111 32.5 95 Z")
        #expect(!body.isEmpty)
        let bounds = body.boundingRect
        #expect(bounds.minY >= 42 && bounds.maxY <= 122)
    }

    @Test func toleratesNegativeAndDecimalNumbers() {
        let path = SVGPath.path("M-5 -5 L5.5 5.5")
        let bounds = path.boundingRect
        #expect(abs(bounds.minX + 5) < 0.001)
        #expect(abs(bounds.maxX - 5.5) < 0.001)
    }
}
