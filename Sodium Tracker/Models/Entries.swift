//
//  Entries.swift
//  Sodium Tracker
//
//  SwiftData models: logged entries, custom foods ("your shelf"), favorites.
//

import Foundation
import SwiftData

/// Meals a log entry can belong to.
enum Meal: String, Codable, CaseIterable, Identifiable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snacks = "Snacks"

    var id: String { rawValue }

    /// Design rule: <11 Breakfast, <15 Lunch, <21 Dinner, else Snacks.
    static func auto(hour: Int) -> Meal {
        if hour < 11 { return .breakfast }
        if hour < 15 { return .lunch }
        if hour < 21 { return .dinner }
        return .snacks
    }

    static func auto(at date: Date = .now, calendar: Calendar = .current) -> Meal {
        auto(hour: calendar.component(.hour, from: date))
    }
}

/// One logged item. Either references a food (built-in or custom) by id, or is
/// an ad-hoc quick log carrying its own name and milligrams.
@Model
final class LogEntry {
    var foodID: String?
    var adhocName: String?
    var adhocMg: Int?
    /// Portion label for ad-hoc entries (e.g. a FatSecret serving like
    /// "1 cup"); nil means the design's "quick log" label.
    var adhocServing: String?
    var servings: Double
    var mealRaw: String
    var loggedAt: Date

    init(
        foodID: String? = nil,
        adhocName: String? = nil,
        adhocMg: Int? = nil,
        adhocServing: String? = nil,
        servings: Double = 1,
        meal: Meal,
        loggedAt: Date = .now
    ) {
        self.foodID = foodID
        self.adhocName = adhocName
        self.adhocMg = adhocMg
        self.adhocServing = adhocServing
        self.servings = servings
        self.mealRaw = meal.rawValue
        self.loggedAt = loggedAt
    }

    var meal: Meal { Meal(rawValue: mealRaw) ?? .snacks }
}

/// A user-created food on "your shelf".
@Model
final class CustomFood {
    @Attribute(.unique) var id: String
    var name: String
    var serving: String
    var mg: Int
    var calories: Int?
    var carbs: Int?
    var protein: Int?
    var fat: Int?
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        serving: String,
        mg: Int,
        calories: Int? = nil,
        carbs: Int? = nil,
        protein: Int? = nil,
        fat: Int? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.serving = serving
        self.mg = mg
        self.calories = calories
        self.carbs = carbs
        self.protein = protein
        self.fat = fat
        self.createdAt = createdAt
    }

    var asFoodItem: FoodItem {
        FoodItem(id: id, name: name, serving: serving, mg: mg, category: .custom)
    }
}

/// A pinned favorite, referencing a built-in or custom food id.
@Model
final class Favorite {
    @Attribute(.unique) var foodID: String
    var addedAt: Date

    init(foodID: String, addedAt: Date = .now) {
        self.foodID = foodID
        self.addedAt = addedAt
    }
}

/// Resolved display info for an entry, independent of storage shape.
struct ResolvedEntry {
    let entry: LogEntry
    let name: String
    let serving: String   // "quick log" for ad-hoc entries, per the design
    let baseMg: Int
    let category: FoodCategory

    var totalMg: Int { Int((Double(baseMg) * entry.servings).rounded()) }
}

enum EntryResolver {
    /// Resolves an entry against the built-in catalog plus the user's shelf.
    static func resolve(_ entry: LogEntry, customFoods: [CustomFood]) -> ResolvedEntry {
        if let name = entry.adhocName, let mg = entry.adhocMg {
            return ResolvedEntry(
                entry: entry,
                name: name,
                serving: entry.adhocServing ?? "quick log",
                baseMg: mg,
                category: .custom
            )
        }
        if let id = entry.foodID {
            if let food = FoodItem.builtIn(id) {
                return ResolvedEntry(entry: entry, name: food.name, serving: food.serving, baseMg: food.mg, category: food.category)
            }
            if let custom = customFoods.first(where: { $0.id == id }) {
                return ResolvedEntry(entry: entry, name: custom.name, serving: custom.serving, baseMg: custom.mg, category: .custom)
            }
        }
        return ResolvedEntry(entry: entry, name: "Unknown", serving: "—", baseMg: 0, category: .custom)
    }
}
