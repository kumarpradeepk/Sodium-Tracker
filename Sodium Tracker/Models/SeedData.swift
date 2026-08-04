//
//  SeedData.swift
//  Sodium Tracker
//
//  First-launch bootstrap. Production health logs must start empty; design
//  previews and tests provide their own sample data.
//

import Foundation
import SwiftData

enum SeedData {
    /// Marks first launch and starts the tracked window without inventing
    /// dietary history or achievement progress.
    static func seedIfNeeded(context: ModelContext, defaults: UserDefaults = .standard, today: Date = .now, calendar: Calendar = .current) {
        guard !defaults.bool(forKey: PinchDefaults.hasSeeded) else { return }
        defaults.set(true, forKey: PinchDefaults.hasSeeded)
        let start = calendar.startOfDay(for: today)
        defaults.set(start.timeIntervalSinceReferenceDate, forKey: PinchDefaults.seedStart)
        _ = context
    }

    /// First day of tracked data ("before Pinch" days are dashed in the calendar).
    static func trackedStart(defaults: UserDefaults = .standard, today: Date = .now, calendar: Calendar = .current) -> Date {
        let stored = defaults.double(forKey: PinchDefaults.seedStart)
        guard stored != 0 else { return calendar.startOfDay(for: today) }
        return Date(timeIntervalSinceReferenceDate: stored)
    }

    /// Stable pseudo-random user id like "pinch-7F3K2".
    static func userID(defaults: UserDefaults = .standard) -> String {
        if let existing = defaults.string(forKey: PinchDefaults.userID) { return existing }
        let alphabet = "23456789ABCDEFGHJKMNPQRSTUVWXYZ"
        let suffix = String((0..<5).compactMap { _ in alphabet.randomElement() })
        let id = "pinch-\(suffix)"
        defaults.set(id, forKey: PinchDefaults.userID)
        return id
    }
}
