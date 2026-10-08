import Foundation
import SwiftData
import Testing
@testable import Sodium_Tracker

@MainActor
struct RhythmTests {
    private var calendar: Calendar {
        var result = Calendar(identifier: .gregorian)
        result.timeZone = TimeZone(identifier: "America/New_York")!
        result.firstWeekday = 2
        return result
    }
    private func date(_ day: Int, month: Int = 9, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour))!
    }
    private func log(_ day: Int, food: String = "yog") -> LogEntry {
        LogEntry(foodID: food, meal: .lunch, loggedAt: date(day))
    }

    @Test func uniqueDaysExcludePreviousWeekAndFuture() {
        let week = RhythmEngine.week([log(6), log(7), log(7), log(8), log(9)], now: date(8, hour: 18), calendar: calendar)
        #expect(week.count == 2)
        #expect(week.entries.count == 3)
        #expect(week.dates.first == calendar.startOfDay(for: date(7)))
        #expect(week.dates.count == 7)
    }

    @Test func regionalWeekAndDaylightSavingUseCalendarDays() {
        var sunday = calendar; sunday.firstWeekday = 1
        let now = date(8, month: 3, hour: 18) // DST transition in New York.
        let mondayWeek = RhythmEngine.week([], now: now, calendar: calendar)
        let sundayWeek = RhythmEngine.week([], now: now, calendar: sunday)
        #expect(calendar.component(.day, from: mondayWeek.dates[0]) == 2)
        #expect(calendar.component(.day, from: sundayWeek.dates[0]) == 8)
        #expect(Set(sundayWeek.dates).count == 7)
        #expect(sundayWeek.dates.allSatisfy { calendar.component(.hour, from: $0) == 0 })
    }

    @Test func emptyAndReturningStatesAreDistinct() {
        #expect(!RhythmEngine.week([], now: date(8), calendar: calendar).isReturning)
        #expect(RhythmEngine.week([log(4)], now: date(8), calendar: calendar).isReturning)
        #expect(!RhythmEngine.week([log(7)], now: date(8), calendar: calendar).isReturning)
        #expect(RhythmEngine.validGoal(99) == 3)
        #expect(RhythmEngine.validGoal(5) == 5)
    }

    @Test func recommendationsRequireRepeatedRealHistoryAndExcludeFavorites() {
        #expect(RhythmEngine.suggestion(entries: [], favorites: [], customFoods: []) == nil)
        #expect(RhythmEngine.suggestion(entries: [log(7)], favorites: [], customFoods: []) == nil)
        let logs = [log(7), log(8), log(8, food: "wrap")]
        let suggestion = RhythmEngine.suggestion(entries: logs, favorites: [], customFoods: [])
        #expect(suggestion?.food.id == "yog")
        #expect(suggestion?.count == 2)
        #expect(RhythmEngine.suggestion(entries: logs, favorites: [Favorite(foodID: "yog")], customFoods: []) == nil)
    }

    @Test func manualFavoriteStaysInSyncAndDoesNotDuplicate() throws {
        let container = try ModelContainer(for: LogEntry.self, CustomFood.self, Favorite.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        let logs = (0..<2).map { _ in LogEntry(adhocName: "My oats", adhocMg: 70, meal: .breakfast, loggedAt: date(7)) }
        let suggestion = try #require(RhythmEngine.suggestion(entries: logs, favorites: [], customFoods: []))
        #expect(try FoodFavoriteStore.pin(suggestion.food, in: context, isPremium: false))
        #expect(try FoodFavoriteStore.pin(suggestion.food, in: context, isPremium: false))
        let favorites = try context.fetch(FetchDescriptor<Favorite>())
        let foods = try context.fetch(FetchDescriptor<CustomFood>())
        #expect(favorites.count == 1 && foods.count == 1)
        #expect(RhythmEngine.suggestion(entries: logs, favorites: favorites, customFoods: foods) == nil)
        let quick = FoodRecommendations.foods(entries: [], favorites: favorites, customFoods: foods)
        #expect(quick.first?.id == suggestion.food.id)
        #expect(quick.first?.mg == 70)
    }

    @Test func savingRespectsShelfLimitAndRemoteAccess() throws {
        let container = try ModelContainer(for: CustomFood.self, Favorite.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        for i in 0..<10 { context.insert(CustomFood(name: "Food \(i)", serving: "1 serving", mg: 20)) }
        try context.save()
        let custom = FoodItem(id: "adhoc:test", name: "Test", serving: "1 serving", mg: 20, category: .custom)
        #expect(try !FoodFavoriteStore.pin(custom, in: context, isPremium: false))
        let remote = FoodItem(id: FatSecretConfig.idPrefix + "test", name: "Remote", serving: "1 serving", mg: 20, category: .custom)
        #expect(try !FoodFavoriteStore.pin(remote, in: context, isPremium: false))
        #expect(try context.fetchCount(FetchDescriptor<Favorite>()) == 0)
        #expect(try FoodFavoriteStore.pin(custom, in: context, isPremium: true))
    }

    @Test func allBadgesStayEarnedAfterStreakBreaks() {
        let now = date(8)
        let logs = (5..<35).map { offset in
            LogEntry(foodID: "yog", meal: .lunch, loggedAt: calendar.date(byAdding: .day, value: -offset, to: now)!)
        }
        let badges = BadgeEngine.badges(entries: logs, customFoods: [], lookupCount: 25,
                                       sleuthEarnedAt: now.addingTimeInterval(-86400), streak: 0, today: now, calendar: calendar)
        #expect(badges.allSatisfy { $0.earned })
        #expect(RhythmEngine.week(logs, now: now, calendar: calendar).isReturning)
    }

    @Test func legacyAwardDateIsMigratedOnce() throws {
        let suite = "RhythmTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let logs = (1...7).map { log($0, food: $0 < 3 ? "ram" : "yog") }
        RhythmEngine.migrateLegacyAward(entries: logs, customFoods: [], defaults: defaults, now: date(8))
        let timestamp = defaults.double(forKey: RhythmEngine.legacyCoolKey)
        #expect(timestamp != 0)
        RhythmEngine.migrateLegacyAward(entries: [], customFoods: [], defaults: defaults, now: date(9))
        #expect(defaults.double(forKey: RhythmEngine.legacyCoolKey) == timestamp)
        let legacyDate = Date(timeIntervalSinceReferenceDate: timestamp)
        let badges = BadgeEngine.badges(entries: logs, customFoods: [], lookupCount: 0, sleuthEarnedAt: nil,
                                       streak: 0, today: date(8), legacyCoolEarnedAt: legacyDate)
        #expect(badges.first { $0.id == "cool" }?.earnedDate == legacyDate)
    }
}
