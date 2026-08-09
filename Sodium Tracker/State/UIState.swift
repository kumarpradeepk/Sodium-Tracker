//
//  UIState.swift
//  Sodium Tracker
//
//  Ephemeral UI state: tab, selected day, sheet stack, form fields, toast,
//  onboarding progress. Persistent preferences live in AppStorage.
//

import SwiftUI
import Observation

enum PinchTab: String, CaseIterable {
    case today, trends, awards, settings

    var order: Int { Self.allCases.firstIndex(of: self) ?? 0 }
}

enum TrendsMode { case week, month }
enum PlusPlan { case yearly, monthly }

struct PinchToast: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let sub: String
}

/// A one-tap add launched from the floating FAB menu. TodayScreen consumes the
/// request only after its amount pill has completed the showcase flight into
/// the progress ring.
struct QuickAddRequest: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let milligrams: Int
}

@Observable
final class UIState {
    // MARK: Navigation
    var tab: PinchTab = .today
    var tabDirection: CGFloat = 1
    var selOffset = 0                 // 0 = today, negative = days back (≥ -13)
    var trMode: TrendsMode = .week
    var weekSel = 0                   // 0 = this week, 1 = last week

    static let minOffset = -13

    // MARK: Log sheet
    var logOpen = false
    var quickAddOpen = false
    var quickAddRequest: QuickAddRequest?
    var search = ""

    // MARK: Portion sheet
    var picked: FoodItem?
    var servings: Double = 1
    var meal: Meal = .lunch

    // MARK: Quick log
    var qlOpen = false
    var qlName = ""
    var qlMg = ""
    var qlUnit: SodiumInputUnit = .sodiumMilligrams
    var qlMeal: Meal = .lunch
    var qlFav = false

    // MARK: Create food
    var cfOpen = false
    var cfName = ""
    var cfServe = ""
    var cfMg = ""
    var cfUnit: SodiumInputUnit = .sodiumMilligrams
    var cfMore = false
    var cfCal = ""
    var cfCarb = ""
    var cfProt = ""
    var cfFat = ""

    // MARK: Other overlays
    var calOpen = false
    var notifCenterOpen = false
    var payOpen = false
    var plan: PlusPlan = .yearly

    // MARK: Toast
    var toast: PinchToast?

    // MARK: Onboarding (persist flag lives in AppStorage; step state here)
    var showOnboarding = false
    var obStep = 0
    var obWhy: String?
    var obDiet: String?

    // MARK: - Intents

    func selectedDay(calendar: Calendar = .current) -> Date {
        DayEngine.day(offset: selOffset, calendar: calendar)
    }

    func showToast(_ title: String, _ sub: String) {
        toast = PinchToast(title: title, sub: sub)
    }

    func selectTab(_ target: PinchTab) {
        guard target != tab else { return }
        tabDirection = target.order >= tab.order ? 1 : -1
        tab = target
    }

    /// Opens the portion sheet for a food and counts the lookup (Label Sleuth).
    func pick(_ food: FoodItem) {
        picked = food
        servings = 1
        meal = Meal.auto()
        let defaults = UserDefaults.standard
        let count = defaults.integer(forKey: PinchDefaults.lookupCount) + 1
        defaults.set(count, forKey: PinchDefaults.lookupCount)
        if count >= 25, defaults.double(forKey: PinchDefaults.sleuthEarnedAt) == 0 {
            defaults.set(Date.now.timeIntervalSinceReferenceDate, forKey: PinchDefaults.sleuthEarnedAt)
        }
    }

    /// Closes every sheet layer (after a successful add).
    func closeAllSheets() {
        picked = nil
        logOpen = false
        quickAddOpen = false
        qlOpen = false
        cfOpen = false
        calOpen = false
        search = ""
    }

    func openQuickLog(prefillName: String = "", prefillMg: String = "") {
        qlName = prefillName
        qlMg = prefillMg
        qlUnit = .sodiumMilligrams
        qlMeal = Meal.auto()
        qlFav = false
        qlOpen = true
    }

    func openCreateFood() {
        cfName = ""
        cfServe = ""
        cfMg = ""
        cfUnit = .sodiumMilligrams
        cfMore = false
        cfCal = ""
        cfCarb = ""
        cfProt = ""
        cfFat = ""
        cfOpen = true
    }

    func beginOnboarding() {
        obStep = 0
        obWhy = nil
        obDiet = nil
        showOnboarding = true
    }
}
