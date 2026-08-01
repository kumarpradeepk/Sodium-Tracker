//
//  Format.swift
//  Sodium Tracker
//

import Foundation

/// Shared display formatting.
enum Format {
    private static let decimal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    /// "1,250"
    static func number(_ value: Int) -> String {
        decimal.string(from: NSNumber(value: value)) ?? String(value)
    }

    /// "1,250 mg"
    static func milligrams(_ value: Int) -> String {
        "\(number(value)) mg"
    }

    /// "1" for whole counts, "1.5" otherwise.
    static func servings(_ value: Double) -> String {
        if value == value.rounded() {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }

    /// "2 servings · 300 mg each", omitting the serving count when it is exactly one.
    static func entrySubtitle(servings: Double, milligramsPerServing: Int) -> String {
        guard servings != 1 else {
            return milligrams(milligramsPerServing)
        }
        return "\(Self.servings(servings)) × \(milligrams(milligramsPerServing))"
    }

    /// "Today", "Yesterday", or a medium date such as "Jul 24, 2026".
    static func dayHeading(for date: Date, calendar: Calendar = .current) -> String {
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(date: .abbreviated, time: .omitted)
    }
}
