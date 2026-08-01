//
//  Sodium_TrackerTests.swift
//  Sodium TrackerTests
//
//  Created by pradeep.kumar1 on 01/08/26.
//

import Testing
import Foundation
@testable import Sodium_Tracker

struct SodiumEntryTests {

    @Test func totalUsesWholeServings() {
        let entry = SodiumEntry(name: "Pizza", milligramsPerServing: 640, servings: 2)
        #expect(entry.totalMilligrams == 1280)
    }

    @Test func totalRoundsFractionalServings() {
        // 145 * 0.25 = 36.25, rounds to 36
        let entry = SodiumEntry(name: "Pinch of salt", milligramsPerServing: 145, servings: 0.25)
        #expect(entry.totalMilligrams == 36)
    }

    @Test func totalDefaultsToOneServing() {
        let entry = SodiumEntry(name: "Bread", milligramsPerServing: 150)
        #expect(entry.totalMilligrams == 150)
    }

    @Test func collectionSumsEntries() {
        let entries = [
            SodiumEntry(name: "Bread", milligramsPerServing: 150),
            SodiumEntry(name: "Soup", milligramsPerServing: 700),
            SodiumEntry(name: "Chips", milligramsPerServing: 170, servings: 2),
        ]
        #expect(entries.totalMilligrams == 1190)
    }

    @Test func emptyCollectionSumsToZero() {
        #expect([SodiumEntry]().totalMilligrams == 0)
    }

    @Test func filtersEntriesToASingleDay() throws {
        let calendar = Calendar.current
        let today = Date.now
        let yesterday = try #require(calendar.date(byAdding: .day, value: -1, to: today))

        let entries = [
            SodiumEntry(name: "Today A", milligramsPerServing: 100, loggedAt: today),
            SodiumEntry(name: "Today B", milligramsPerServing: 200, loggedAt: today),
            SodiumEntry(name: "Yesterday", milligramsPerServing: 900, loggedAt: yesterday),
        ]

        #expect(entries.onSameDay(as: today).totalMilligrams == 300)
        #expect(entries.onSameDay(as: yesterday).totalMilligrams == 900)
    }
}

struct IntakeStatusTests {

    @Test func belowThreeQuartersIsOnTrack() {
        #expect(IntakeStatus(total: 0, goal: 2300) == .onTrack)
        #expect(IntakeStatus(total: 1724, goal: 2300) == .onTrack)
    }

    @Test func betweenThreeQuartersAndGoalIsClose() {
        #expect(IntakeStatus(total: 1725, goal: 2300) == .closeToLimit)
        #expect(IntakeStatus(total: 2299, goal: 2300) == .closeToLimit)
    }

    @Test func atOrAboveGoalIsOver() {
        #expect(IntakeStatus(total: 2300, goal: 2300) == .overLimit)
        #expect(IntakeStatus(total: 4000, goal: 2300) == .overLimit)
    }

    @Test func nonPositiveGoalDoesNotDivideByZero() {
        #expect(IntakeStatus(total: 500, goal: 0) == .onTrack)
    }
}

struct FormatTests {

    @Test func milligramsAppendsUnit() {
        #expect(Format.milligrams(950) == "950 mg")
        #expect(Format.milligrams(0) == "0 mg")
    }

    @Test func largeMilligramsStayLabelled() {
        // The grouping separator is locale-dependent, so only the unit is asserted.
        #expect(Format.milligrams(1250).hasSuffix(" mg"))
    }

    @Test func servingsDropTrailingZero() {
        #expect(Format.servings(1) == "1")
        #expect(Format.servings(3) == "3")
        #expect(Format.servings(1.5) == "1.5")
        #expect(Format.servings(0.5) == "0.5")
    }

    @Test func subtitleOmitsServingCountWhenSingle() {
        #expect(Format.entrySubtitle(servings: 1, milligramsPerServing: 300) == "300 mg")
    }

    @Test func subtitleShowsMultiplierWhenNotSingle() {
        #expect(Format.entrySubtitle(servings: 2, milligramsPerServing: 300) == "2 × 300 mg")
    }

    @Test func dayHeadingUsesRelativeNames() throws {
        let calendar = Calendar.current
        let yesterday = try #require(calendar.date(byAdding: .day, value: -1, to: .now))

        #expect(Format.dayHeading(for: .now) == "Today")
        #expect(Format.dayHeading(for: yesterday) == "Yesterday")
    }

    @Test func dayHeadingFallsBackToADate() throws {
        let calendar = Calendar.current
        let lastWeek = try #require(calendar.date(byAdding: .day, value: -7, to: .now))
        let heading = Format.dayHeading(for: lastWeek)

        #expect(heading != "Today")
        #expect(heading != "Yesterday")
        #expect(!heading.isEmpty)
    }
}

struct FoodPresetTests {

    @Test func catalogIsPopulatedAndSane() {
        #expect(!FoodPreset.catalog.isEmpty)

        for preset in FoodPreset.catalog {
            #expect(preset.milligrams > 0, "\(preset.name) has a non-positive sodium value")
            #expect(!preset.name.isEmpty)
            #expect(!preset.detail.isEmpty)
        }
    }

    @Test func everyCategoryHasEntries() {
        for category in FoodPreset.Category.allCases {
            let items = FoodPreset.catalog.filter { $0.category == category }
            #expect(!items.isEmpty, "\(category.rawValue) has no presets")
        }
    }

    @Test func emptyQueryReturnsEverything() {
        #expect(FoodPreset.matching("").count == FoodPreset.catalog.count)
        #expect(FoodPreset.matching("   ").count == FoodPreset.catalog.count)
    }

    @Test func searchIsCaseInsensitive() {
        let results = FoodPreset.matching("PIZZA")
        #expect(results.contains { $0.name == "Pizza" })
    }

    @Test func searchMatchesCategoryName() {
        let results = FoodPreset.matching("snacks")
        #expect(!results.isEmpty)
        #expect(results.allSatisfy { $0.category == .snacks })
    }

    @Test func unmatchedQueryReturnsNothing() {
        #expect(FoodPreset.matching("zzzzzznotafood").isEmpty)
    }
}
