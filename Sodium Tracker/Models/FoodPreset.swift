//
//  FoodPreset.swift
//  Sodium Tracker
//

import Foundation

/// A common food or drink with a typical sodium value, offered for quick logging.
///
/// Values are rounded typical amounts drawn from published nutrition data. They are
/// a starting point — a label on the actual product is always more accurate.
struct FoodPreset: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let detail: String
    let milligrams: Int
    let category: Category

    enum Category: String, CaseIterable, Identifiable {
        case saltAndSauces = "Salt & sauces"
        case bakedGoods = "Bread & grains"
        case meatsAndCheese = "Meat & cheese"
        case preparedMeals = "Prepared meals"
        case snacks = "Snacks"
        case pantry = "Pantry & canned"

        var id: String { rawValue }

        var symbol: String {
            switch self {
            case .saltAndSauces: return "drop.fill"
            case .bakedGoods: return "birthday.cake"
            case .meatsAndCheese: return "fork.knife"
            case .preparedMeals: return "takeoutbag.and.cup.and.straw"
            case .snacks: return "popcorn"
            case .pantry: return "shippingbox"
            }
        }
    }
}

extension FoodPreset {
    /// The built-in quick-add catalog.
    static let catalog: [FoodPreset] = [
        // Salt & sauces
        FoodPreset(name: "Pinch of salt", detail: "1/16 tsp", milligrams: 145, category: .saltAndSauces),
        FoodPreset(name: "Table salt", detail: "1/4 tsp", milligrams: 575, category: .saltAndSauces),
        FoodPreset(name: "Soy sauce", detail: "1 tbsp", milligrams: 900, category: .saltAndSauces),
        FoodPreset(name: "Ketchup", detail: "1 tbsp", milligrams: 150, category: .saltAndSauces),
        FoodPreset(name: "Mustard", detail: "1 tsp", milligrams: 55, category: .saltAndSauces),
        FoodPreset(name: "Salad dressing", detail: "2 tbsp", milligrams: 300, category: .saltAndSauces),
        FoodPreset(name: "Hot sauce", detail: "1 tsp", milligrams: 125, category: .saltAndSauces),

        // Bread & grains
        FoodPreset(name: "Bread", detail: "1 slice", milligrams: 150, category: .bakedGoods),
        FoodPreset(name: "Bagel", detail: "1 medium", milligrams: 430, category: .bakedGoods),
        FoodPreset(name: "Flour tortilla", detail: "1 medium", milligrams: 200, category: .bakedGoods),
        FoodPreset(name: "Biscuit", detail: "1 medium", milligrams: 580, category: .bakedGoods),
        FoodPreset(name: "Breakfast cereal", detail: "1 cup", milligrams: 200, category: .bakedGoods),

        // Meat & cheese
        FoodPreset(name: "Deli turkey", detail: "2 oz", milligrams: 550, category: .meatsAndCheese),
        FoodPreset(name: "Ham", detail: "2 oz", milligrams: 750, category: .meatsAndCheese),
        FoodPreset(name: "Bacon", detail: "3 slices", milligrams: 580, category: .meatsAndCheese),
        FoodPreset(name: "Cheddar cheese", detail: "1 oz", milligrams: 180, category: .meatsAndCheese),
        FoodPreset(name: "Cottage cheese", detail: "1/2 cup", milligrams: 350, category: .meatsAndCheese),
        FoodPreset(name: "Rotisserie chicken", detail: "3 oz", milligrams: 400, category: .meatsAndCheese),
        FoodPreset(name: "Hot dog", detail: "1 link", milligrams: 570, category: .meatsAndCheese),

        // Prepared meals
        FoodPreset(name: "Pizza", detail: "1 slice", milligrams: 640, category: .preparedMeals),
        FoodPreset(name: "Instant ramen", detail: "1 package", milligrams: 1700, category: .preparedMeals),
        FoodPreset(name: "Canned soup", detail: "1 cup", milligrams: 700, category: .preparedMeals),
        FoodPreset(name: "Deli sandwich", detail: "1 whole", milligrams: 1500, category: .preparedMeals),
        FoodPreset(name: "Fast food burger", detail: "1 sandwich", milligrams: 1000, category: .preparedMeals),
        FoodPreset(name: "Burrito", detail: "1 large", milligrams: 1300, category: .preparedMeals),
        FoodPreset(name: "Frozen dinner", detail: "1 tray", milligrams: 850, category: .preparedMeals),
        FoodPreset(name: "Scrambled eggs", detail: "2 eggs", milligrams: 340, category: .preparedMeals),

        // Snacks
        FoodPreset(name: "French fries", detail: "medium", milligrams: 260, category: .snacks),
        FoodPreset(name: "Tortilla chips", detail: "1 oz", milligrams: 120, category: .snacks),
        FoodPreset(name: "Potato chips", detail: "1 oz", milligrams: 170, category: .snacks),
        FoodPreset(name: "Salted pretzels", detail: "1 oz", milligrams: 350, category: .snacks),
        FoodPreset(name: "Salted nuts", detail: "1 oz", milligrams: 190, category: .snacks),
        FoodPreset(name: "Popcorn, microwave", detail: "1 bag", milligrams: 500, category: .snacks),

        // Pantry & canned
        FoodPreset(name: "Canned beans", detail: "1/2 cup", milligrams: 400, category: .pantry),
        FoodPreset(name: "Canned tuna", detail: "3 oz", milligrams: 300, category: .pantry),
        FoodPreset(name: "Olives", detail: "5 olives", milligrams: 330, category: .pantry),
        FoodPreset(name: "Pickle spear", detail: "1 spear", milligrams: 300, category: .pantry),
        FoodPreset(name: "Pasta sauce", detail: "1/2 cup", milligrams: 450, category: .pantry),
        FoodPreset(name: "Broth", detail: "1 cup", milligrams: 860, category: .pantry),
    ]

    /// Catalog entries matching a free-text query, grouped in catalog order.
    static func matching(_ query: String) -> [FoodPreset] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return catalog }
        return catalog.filter {
            $0.name.localizedCaseInsensitiveContains(trimmed)
                || $0.category.rawValue.localizedCaseInsensitiveContains(trimmed)
        }
    }
}
