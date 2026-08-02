//
//  Food.swift
//  Sodium Tracker
//
//  The built-in food catalog and category icons, verbatim from the design.
//

import Foundation

/// Icon family for a food; each has a line-drawn SVG path (20×20 viewBox).
enum FoodCategory: String, Codable, CaseIterable {
    case breakfast = "bfast"
    case meal
    case snack
    case pantry
    case drink
    case fresh
    case custom

    /// 1.6px line-drawing path from the design.
    var iconPath: String {
        switch self {
        case .breakfast:
            return "M10 3.5 C13.2 3.5 15.5 8 15.5 11.8 C15.5 15 13 17.5 10 17.5 C7 17.5 4.5 15 4.5 11.8 C4.5 8 6.8 3.5 10 3.5 Z"
        case .meal:
            return "M3 11 H17 C17 15 14 17.5 10 17.5 C6 17.5 3 15 3 11 Z M7.5 7.5 C7.5 6 9 6 9 4.5 M12 7.5 C12 6 13.5 6 13.5 4.5"
        case .snack:
            return "M10 3 L17 16.5 H3 Z M8.4 12.6 L8.5 12.5 M11.6 10.4 L11.7 10.3 M9.6 8.4 L9.7 8.3"
        case .pantry:
            return "M6.5 7.5 H13.5 V15.5 C13.5 16.6 12.6 17.5 11.5 17.5 H8.5 C7.4 17.5 6.5 16.6 6.5 15.5 Z M7.5 7.5 V5.5 H12.5 V7.5 M7 4 H13"
        case .drink:
            return "M5.5 5 H14.5 L13.3 16.4 C13.2 17 12.7 17.5 12.1 17.5 H7.9 C7.3 17.5 6.8 17 6.7 16.4 Z M5.9 9 H14.1"
        case .fresh:
            return "M4.5 15.5 C4.5 8.5 9.5 4.5 15.5 4.5 C15.5 11.5 11 15.5 4.5 15.5 Z M4.5 15.5 C7.5 11.5 9.5 9.5 12.5 7.5"
        case .custom:
            return "M10 3 L11.6 7.2 L16 7.6 L12.7 10.5 L13.8 15 L10 12.6 L6.2 15 L7.3 10.5 L4 7.6 L8.4 7.2 Z"
        }
    }
}

/// One item on the salt shelf: a name, a stated portion, and its sodium.
struct FoodItem: Identifiable, Hashable {
    let id: String
    let name: String
    let serving: String
    let mg: Int
    let category: FoodCategory
}

extension FoodItem {
    /// The design's built-in database, ids and values verbatim.
    static let catalog: [FoodItem] = [
        FoodItem(id: "yog", name: "Greek yogurt", serving: "¾ cup", mg: 65, category: .breakfast),
        FoodItem(id: "sour", name: "Sourdough toast", serving: "1 slice", mg: 220, category: .breakfast),
        FoodItem(id: "bagel", name: "Plain bagel", serving: "1 whole", mg: 430, category: .breakfast),
        FoodItem(id: "bac", name: "Bacon", serving: "2 slices", mg: 376, category: .breakfast),
        FoodItem(id: "egg", name: "Eggs", serving: "2 large", mg: 142, category: .breakfast),
        FoodItem(id: "oat", name: "Instant oatmeal", serving: "1 packet", mg: 260, category: .breakfast),
        FoodItem(id: "cot", name: "Cottage cheese", serving: "½ cup", mg: 350, category: .breakfast),
        FoodItem(id: "wrap", name: "Chicken salad wrap", serving: "1 wrap", mg: 610, category: .meal),
        FoodItem(id: "ram", name: "Instant ramen", serving: "1 pack", mg: 1560, category: .meal),
        FoodItem(id: "piz", name: "Pepperoni pizza", serving: "1 slice", mg: 683, category: .meal),
        FoodItem(id: "soup", name: "Canned chicken soup", serving: "1 cup", mg: 870, category: .meal),
        FoodItem(id: "burg", name: "Cheeseburger", serving: "1 burger", mg: 1050, category: .meal),
        FoodItem(id: "burr", name: "Burrito bowl", serving: "1 bowl", mg: 1350, category: .meal),
        FoodItem(id: "sushi", name: "Sushi with soy", serving: "6 pieces", mg: 920, category: .meal),
        FoodItem(id: "caes", name: "Caesar salad", serving: "1 bowl", mg: 470, category: .meal),
        FoodItem(id: "miso", name: "Miso soup", serving: "1 cup", mg: 630, category: .meal),
        FoodItem(id: "del", name: "Deli turkey", serving: "2 oz", mg: 440, category: .meal),
        FoodItem(id: "chick", name: "Grilled chicken", serving: "4 oz", mg: 74, category: .meal),
        FoodItem(id: "fries", name: "French fries", serving: "medium", mg: 260, category: .meal),
        FoodItem(id: "pick", name: "Dill pickle", serving: "1 spear", mg: 283, category: .snack),
        FoodItem(id: "alm", name: "Salted almonds", serving: "28 g", mg: 96, category: .snack),
        FoodItem(id: "chip", name: "Potato chips", serving: "28 g", mg: 148, category: .snack),
        FoodItem(id: "pret", name: "Pretzels", serving: "28 g", mg: 352, category: .snack),
        FoodItem(id: "ched", name: "Cheddar", serving: "1 oz", mg: 180, category: .snack),
        FoodItem(id: "eda", name: "Salted edamame", serving: "1 cup", mg: 220, category: .snack),
        FoodItem(id: "soy", name: "Soy sauce", serving: "1 tbsp", mg: 879, category: .pantry),
        FoodItem(id: "ket", name: "Ketchup", serving: "1 tbsp", mg: 160, category: .pantry),
        FoodItem(id: "ranch", name: "Ranch dressing", serving: "2 tbsp", mg: 260, category: .pantry),
        FoodItem(id: "milk", name: "2% milk", serving: "1 cup", mg: 105, category: .drink),
        FoodItem(id: "tea", name: "Unsweet iced tea", serving: "16 oz", mg: 15, category: .drink),
        FoodItem(id: "ban", name: "Banana", serving: "1 medium", mg: 1, category: .fresh),
        FoodItem(id: "appl", name: "Apple", serving: "1 medium", mg: 2, category: .fresh),
    ]

    static func builtIn(_ id: String) -> FoodItem? {
        catalog.first { $0.id == id }
    }
}

/// The Today screen's quick-add chips, in design order.
enum UsualSuspects {
    static let ids = ["wrap", "ram", "pick", "yog"]
}
