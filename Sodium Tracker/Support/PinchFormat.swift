//
//  PinchFormat.swift
//  Sodium Tracker
//
//  Number and date formatting matching the design: en-US thousands separators
//  ("2,300"), fraction glyphs for half servings, and the design's date styles.
//

import Foundation

enum PinchFormat {
    /// Use the device/app locale so dates and grouping follow the selected
    /// storefront (en-GB, en-AU, en-CA, ja-JP, de-DE, or en-US).
    static let locale = Locale.current

    private static let grouping: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = locale
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()

    /// "2,300" — rounded, comma-grouped.
    static func mg(_ value: Double) -> String {
        grouping.string(from: NSNumber(value: value.rounded())) ?? String(Int(value.rounded()))
    }

    static func mg(_ value: Int) -> String {
        grouping.string(from: NSNumber(value: value)) ?? String(value)
    }

    /// Servings label: ½, 1, 1½, 2, 2½ … (steps of 0.5 up to 4).
    static func servings(_ value: Double) -> String {
        switch value {
        case 0.5: return "½"
        case 1.5: return "1½"
        case 2.5: return "2½"
        case 3.5: return "3½"
        default:
            if value == value.rounded() { return String(Int(value)) }
            return String(value)
        }
    }

    /// "2.0k" for chart bar labels.
    static func thousands(_ value: Double) -> String {
        String(format: "%.1fk", (value / 100).rounded() / 10)
    }

    /// "SATURDAY, AUGUST 1" — the Today kicker.
    static func kicker(_ date: Date, calendar: Calendar = .current) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.calendar = calendar
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: date).uppercased()
    }

    /// "Sat, Aug 1" — history rows.
    static func shortDay(_ date: Date, calendar: Calendar = .current) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.calendar = calendar
        f.dateFormat = "EEE, MMM d"
        return f.string(from: date)
    }

    /// "Jul 26 – Aug 1" — trends week range.
    static func weekRange(from start: Date, to end: Date, calendar: Calendar = .current) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.calendar = calendar
        f.dateFormat = "MMM d"
        let a = f.string(from: start)
        let b = f.string(from: end)
        // Same month collapses to "Jul 19 – 25".
        let m = DateFormatter()
        m.locale = locale
        m.calendar = calendar
        m.dateFormat = "MMM"
        if m.string(from: start) == m.string(from: end) {
            let d = DateFormatter()
            d.locale = locale
            d.calendar = calendar
            d.dateFormat = "d"
            return "\(a) – \(d.string(from: end))"
        }
        return "\(a) – \(b)"
    }

    /// "9:41 AM" — entry timestamps.
    static func time(_ date: Date, calendar: Calendar = .current) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.calendar = calendar
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }

    /// "JUL 19" — badge earn dates.
    static func badgeDate(_ date: Date, calendar: Calendar = .current) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.calendar = calendar
        f.dateFormat = "MMM d"
        return f.string(from: date).uppercased()
    }

    /// Screen title for a day: "Today", "Yesterday", else weekday name.
    static func dayTitle(_ date: Date, calendar: Calendar = .current) -> String {
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter()
        f.locale = locale
        f.calendar = calendar
        f.dateFormat = "EEEE"
        return f.string(from: date)
    }
}
