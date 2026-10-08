import Foundation
import SwiftData

/// Logging activity, not a health score or a claim of complete dietary intake.
enum RhythmEngine {
    static let goalKey = "pinch.rhythm.weeklyGoal"
    static let legacyCoolKey = "pinch.rhythm.legacyCoolDate"
    static let migratedKey = "pinch.rhythm.migrated"
    static let goals = [3, 4, 5]

    struct Week {
        let dates: [Date]
        let logged: Set<Date>
        let entries: [LogEntry]
        let isReturning: Bool
        var count: Int { logged.count }
    }

    static func validGoal(_ value: Int) -> Int { goals.contains(value) ? value : 3 }

    static func week(_ entries: [LogEntry], now: Date = .now, calendar: Calendar = .current) -> Week {
        let today = calendar.startOfDay(for: now)
        let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? today
        let dates = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
        let realEntries = entries.filter { $0.loggedAt <= now }
        let thisWeek = realEntries.filter { $0.loggedAt >= start }
        let latest = realEntries.map(\.loggedAt).max()
        let gap = latest.map { calendar.dateComponents([.day], from: calendar.startOfDay(for: $0), to: today).day ?? 0 } ?? 0
        return Week(dates: dates, logged: Set(thisWeek.map { calendar.startOfDay(for: $0.loggedAt) }),
                    entries: thisWeek, isReturning: gap >= 3)
    }

    struct Suggestion { let food: FoodItem; let count: Int }

    /// Uses canonical search/quick-add IDs; never fills empty history with stock foods.
    static func suggestion(entries: [LogEntry], favorites: [Favorite], customFoods: [CustomFood]) -> Suggestion? {
        let pinned = Set(favorites.map(\.foodID))
        var counts: [String: Int] = [:]
        for entry in entries {
            if let food = FoodRecommendations.foods(entries: [entry], favorites: [], customFoods: customFoods,
                                                     limit: 1, includeCatalogSuggestions: false).first {
                counts[food.id, default: 0] += 1
            }
        }
        let ranked = FoodRecommendations.foods(entries: entries, favorites: [], customFoods: customFoods,
                                               limit: counts.count, includeCatalogSuggestions: false)
        guard let food = ranked.first(where: { !pinned.contains($0.id) && counts[$0.id, default: 0] >= 2 }) else { return nil }
        return Suggestion(food: food, count: counts[food.id, default: 0])
    }

    /// Preserve the existing award date once, before replacing intake-based criteria.
    static func migrateLegacyAward(entries: [LogEntry], customFoods: [CustomFood], defaults: UserDefaults = .standard, now: Date = .now) {
        guard !defaults.bool(forKey: migratedKey) else { return }
        let badges = BadgeEngine.badges(entries: entries, customFoods: customFoods, lookupCount: 0,
                                       sleuthEarnedAt: nil, streak: 0, today: now, legacyCoolRule: true)
        if let date = badges.first(where: { $0.id == "cool" })?.earnedDate {
            defaults.set(date.timeIntervalSinceReferenceDate, forKey: legacyCoolKey)
        }
        defaults.set(true, forKey: migratedKey)
    }
}

/// The same save path for the portion sheet and Rhythm. Remote/manual favorites
/// keep an offline shelf record and obey the existing premium/shelf limits.
@MainActor
enum FoodFavoriteStore {
    static func pin(_ food: FoodItem, in context: ModelContext, isPremium: Bool) throws -> Bool {
        let favorites = try context.fetch(FetchDescriptor<Favorite>())
        if favorites.contains(where: { $0.foodID == food.id }) { return true }
        if food.id.hasPrefix(FatSecretConfig.idPrefix),
           !PremiumAccessPolicy.allows(.remoteFoodLogging, isPremium: isPremium) { return false }
        let shelf = try context.fetch(FetchDescriptor<CustomFood>())
        var inserted: CustomFood?
        if FoodItem.builtIn(food.id) == nil && !shelf.contains(where: { $0.id == food.id }) {
            guard PremiumAccessPolicy.allows(.unlimitedCustomFoods, isPremium: isPremium, customFoodCount: shelf.count) else { return false }
            let saved = CustomFood(id: food.id, name: food.name, serving: food.serving, mg: food.mg,
                                   usesDefaultServing: food.usesDefaultServing)
            context.insert(saved)
            inserted = saved
        }
        let favorite = Favorite(foodID: food.id)
        context.insert(favorite)
        do { try context.save() }
        catch {
            context.delete(favorite)
            if let inserted { context.delete(inserted) }
            throw error
        }
        return true
    }
}
