//
//  PinchWidgetSnapshot.swift
//  Sodium Tracker
//
//  The app-side projection shared with the WidgetKit extension. The extension
//  never reads SwiftData or StoreKit directly; it only renders this snapshot.
//

import Foundation
import WidgetKit

enum PinchWidgetSnapshotStore {
    static let appGroup = "group.com.kabi.sodium.tracker"
    static let key = "pinch.widget.snapshot.v1"

    struct Snapshot: Codable {
        let consumed: Int
        let goal: Int
        let remaining: Int
        let streak: Int
        let isPremium: Bool
    }

    static func update(
        entries: [LogEntry],
        customFoods: [CustomFood],
        goal: Int,
        isPremium: Bool
    ) {
        let total = DayEngine.total(entries, on: .now, customFoods: customFoods)
        let snapshot = Snapshot(
            consumed: isPremium ? total : 0,
            goal: isPremium ? max(goal, 1) : 0,
            remaining: isPremium ? goal - total : 0,
            streak: isPremium ? DayEngine.streak(entries) : 0,
            isPremium: isPremium
        )
        guard let data = try? JSONEncoder().encode(snapshot),
              let defaults = UserDefaults(suiteName: appGroup) else { return }
        defaults.set(data, forKey: key)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
