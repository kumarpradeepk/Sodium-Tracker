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
    static var locale: Locale { PinchLocalization.locale }

    private static var grouping: NumberFormatter {
        let f = NumberFormatter()
        f.locale = locale
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }

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
            return value.formatted(.number.locale(locale))
        }
    }

    /// "2.0k" for chart bar labels.
    static func thousands(_ value: Double) -> String {
        ((value / 100).rounded() / 10).formatted(.number.precision(.fractionLength(1)).locale(locale)) + "k"
    }

    /// "SATURDAY, AUGUST 1" — the Today kicker.
    static func kicker(_ date: Date, calendar: Calendar = .current) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.calendar = calendar
        f.setLocalizedDateFormatFromTemplate("EEEEMMMMd")
        return f.string(from: date).uppercased()
    }

    /// "Sat, Aug 1" — history rows.
    static func shortDay(_ date: Date, calendar: Calendar = .current) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.calendar = calendar
        f.setLocalizedDateFormatFromTemplate("EEEMMMd")
        return f.string(from: date)
    }

    /// "Jul 26 – Aug 1" — trends week range.
    static func weekRange(from start: Date, to end: Date, calendar: Calendar = .current) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.calendar = calendar
        f.setLocalizedDateFormatFromTemplate("MMMd")
        let a = f.string(from: start)
        let b = f.string(from: end)
        // Keep both localized endpoints; month/day order differs by language.
        return "\(a) – \(b)"
    }

    /// "9:41 AM" — entry timestamps.
    static func time(_ date: Date, calendar: Calendar = .current) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.calendar = calendar
        f.setLocalizedDateFormatFromTemplate("jm")
        return f.string(from: date)
    }

    /// "JUL 19" — badge earn dates.
    static func badgeDate(_ date: Date, calendar: Calendar = .current) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.calendar = calendar
        f.setLocalizedDateFormatFromTemplate("MMMd")
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

    static var weekdaySymbols: [String] {
        weekdaySymbols(calendar: .current)
    }

    static func weekdaySymbols(calendar: Calendar) -> [String] {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        let symbols = formatter.veryShortStandaloneWeekdaySymbols ?? []
        guard symbols.count == 7 else { return symbols }
        let start = (calendar.firstWeekday - 1 + 7) % 7
        return Array(symbols[start...] + symbols[..<start])
    }

    static func weekdayColumn(for date: Date, calendar: Calendar = .current) -> Int {
        (calendar.component(.weekday, from: date) - calendar.firstWeekday + 7) % 7
    }

    static func clock(hour: Int, minute: Int) -> String {
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: hour, minute: minute)) ?? .now
        return time(date)
    }
}
