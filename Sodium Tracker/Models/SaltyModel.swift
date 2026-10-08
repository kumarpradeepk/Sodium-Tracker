//
//  SaltyModel.swift
//  Sodium Tracker
//
//  Pure derivations for the Salty dashboard: bubble copy, resting mood, chip
//  fit badges and the quick-add shortlist. No SwiftUI, no SwiftData — so every
//  branch in the design's copy table is unit-testable.
//
//  Spec: docs/superpowers/specs/2026-08-09-salty-dashboard-design.md §6, §11.2, §12
//

import Foundation

enum SaltyModel {

    // MARK: - Mood (spec §6 resting-mood rule)

    /// Today: over → worried, under 150 mg left → concern, else happy.
    /// Past days: over → worried, else happy.
    static func restingMood(remaining: Int, isToday: Bool) -> SaltyMood {
        if remaining < 0 { return .worried }
        guard isToday else { return .happy }
        return remaining < 150 ? .concern : .happy
    }

    // MARK: - Bubble copy (spec §12, verbatim)

    /// Today's line. `fits` is how many usual-suspect chips still fit.
    static func todayBubble(remaining: Int, fits: Int) -> String {
        if remaining < 0 {
            return PinchLocalization.format("{0} mg over budget. Ease up tonight — tomorrow resets.", [String(describing: PinchFormat.mg(-remaining))])
        }
        if fits == 0 {
            return PinchLocalization.format("{0} mg left — under every usual pick. Go fresh for dinner.", [String(describing: PinchFormat.mg(remaining))])
        }
        if remaining < 300 {
            return PinchLocalization.format("{0} mg left — a light bite still fits.", [String(describing: PinchFormat.mg(remaining))])
        }
        return PinchLocalization.format("{0} mg left — {1} of your usual picks fit.", [String(describing: PinchFormat.mg(remaining)), String(describing: fits)])
    }

    /// A past day's line. Generic templates in the design's voice (spec §15.5).
    static func pastBubble(total: Int, remaining: Int, isEmpty: Bool) -> String {
        if isEmpty { return "A quiet page in the log book." }
        if remaining < 0 { return PinchLocalization.format("Finished {0} mg over budget.", [String(describing: PinchFormat.mg(-remaining))]) }
        return PinchLocalization.format("Closed at {0} — {1} mg under budget. Nice save.", [String(describing: PinchFormat.mg(total)), String(describing: PinchFormat.mg(remaining))])
    }

    /// The bubble for whichever day is showing.
    static func bubble(total: Int, remaining: Int, isToday: Bool, isEmpty: Bool, fits: Int) -> String {
        isToday
            ? todayBubble(remaining: remaining, fits: fits)
            : pastBubble(total: total, remaining: remaining, isEmpty: isEmpty)
    }

    // MARK: - Chips

    /// A chip fits only on today, and only if it still lands inside the budget.
    static func fits(mg: Int, remaining: Int, isToday: Bool) -> Bool {
        isToday && mg <= remaining
    }

    /// How many of `foods` fit — drives the "N of your usual picks fit" line.
    static func fitCount(_ foods: [FoodItem], remaining: Int) -> Int {
        foods.filter { $0.mg <= remaining }.count
    }

    // MARK: - Quick add (spec §11.2)

    /// The design's fallbacks, used when there's not enough history.
    static let defaultQuickAdds: [QuickAddItem] = [
        QuickAddItem(id: "qa-fresh", name: "Fresh dinner", mg: 380, food: nil),
        QuickAddItem(id: "qa-soup", name: "Soup cup", mg: 290, food: nil),
        QuickAddItem(id: "qa-snack", name: "Light snack", mg: 150, food: nil),
    ]

    /// Three most-frequently-logged foods, ties broken by most recent; topped
    /// up from the design's defaults when history is thin.
    static func quickAdds(from entries: [LogEntry], customFoods: [CustomFood]) -> [QuickAddItem] {
        var counts: [String: Int] = [:]
        var latest: [String: Date] = [:]
        for entry in entries {
            guard let id = entry.foodID else { continue }
            counts[id, default: 0] += 1
            if let seen = latest[id] {
                latest[id] = max(seen, entry.loggedAt)
            } else {
                latest[id] = entry.loggedAt
            }
        }

        let ranked = counts.keys.sorted { a, b in
            let ca = counts[a] ?? 0, cb = counts[b] ?? 0
            if ca != cb { return ca > cb }
            return (latest[a] ?? .distantPast) > (latest[b] ?? .distantPast)
        }

        var picks: [QuickAddItem] = []
        for id in ranked where picks.count < 3 {
            let food = FoodItem.builtIn(id) ?? customFoods.first { $0.id == id }?.asFoodItem
            guard let food else { continue }
            picks.append(QuickAddItem(id: food.id, name: food.name, mg: food.mg, food: food))
        }

        for fallback in defaultQuickAdds where picks.count < 3 {
            picks.append(fallback)
        }
        return picks
    }
}

/// One row in the QUICK ADD sheet. `food` is nil for the design's ad-hoc
/// defaults, which log as quick entries.
struct QuickAddItem: Identifiable, Equatable {
    let id: String
    let name: String
    let mg: Int
    let food: FoodItem?
}
