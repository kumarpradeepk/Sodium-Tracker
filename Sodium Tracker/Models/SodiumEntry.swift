//
//  SodiumEntry.swift
//  Sodium Tracker
//

import Foundation
import SwiftData

/// A single logged item of food or drink and the sodium it contributed.
@Model
final class SodiumEntry {
    /// What was eaten, e.g. "Instant ramen".
    var name: String

    /// Sodium in a single serving, in milligrams.
    var milligramsPerServing: Int

    /// How many servings were eaten. Supports halves and quarters.
    var servings: Double

    /// When the item was logged.
    var loggedAt: Date

    init(
        name: String,
        milligramsPerServing: Int,
        servings: Double = 1,
        loggedAt: Date = .now
    ) {
        self.name = name
        self.milligramsPerServing = milligramsPerServing
        self.servings = servings
        self.loggedAt = loggedAt
    }

    /// Total sodium this entry contributed, accounting for servings.
    var totalMilligrams: Int {
        Int((Double(milligramsPerServing) * servings).rounded())
    }
}

extension Array where Element == SodiumEntry {
    /// Sum of sodium across the entries, in milligrams.
    var totalMilligrams: Int {
        reduce(0) { $0 + $1.totalMilligrams }
    }

    /// Entries that fall on the same calendar day as `date`.
    func onSameDay(as date: Date, calendar: Calendar = .current) -> [SodiumEntry] {
        filter { calendar.isDate($0.loggedAt, inSameDayAs: date) }
    }
}
