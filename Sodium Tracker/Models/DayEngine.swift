//
//  DayEngine.swift
//  Sodium Tracker
//
//  Pure derivations over logged entries: day totals, streaks, week/month stats,
//  search ranking and badges. Everything the design computes reactively.
//

import Foundation

/// Which daily budget the user picked.
enum GoalChoice: String, CaseIterable {
    case aha      // 1,500 strict
    case fda      // 2,300 standard
    case custom

    func milligrams(custom: Int) -> Int {
        switch self {
        case .aha: return 1500
        case .fda: return 2300
        case .custom: return custom
        }
    }
}

enum PinchDefaults {
    static let theme = "theme"                       // "light" | "dark"
    static let goalChoice = "goalChoice"             // GoalChoice raw
    static let customGoal = "customGoal"             // 500...4000 step 50
    static let chatty = "chatty"                     // Pinch's chatter
    static let notif = "notif"                       // meal check-ins master
    static let health = "health"                     // Apple Health sync pref
    static let plus = "plus"                         // Pinch Plus active
    static let mealRemBreakfast = "mealRemBreakfast"
    static let mealRemLunch = "mealRemLunch"
    static let mealRemDinner = "mealRemDinner"
    static let hasOnboarded = "hasOnboarded"
    static let hasSeeded = "hasSeeded"
    static let seedStart = "seedStartDay"            // timeIntervalSinceReferenceDate
    static let userID = "userID"
    static let lookupCount = "lookupCount"           // foods opened in the portion sheet
    static let sleuthEarnedAt = "sleuthEarnedAt"     // timeIntervalSinceReferenceDate, 0 = not earned
    static let obWhy = "obWhy"
    static let obDiet = "obDiet"

    static let customGoalDefault = 2000
    static let customGoalRange = 500...4000
    static let customGoalStep = 50
}

/// Aggregations for one calendar day.
struct DayStats {
    let date: Date
    let entries: [ResolvedEntry]

    var totalMg: Int { entries.reduce(0) { $0 + $1.totalMg } }
    var isEmpty: Bool { entries.isEmpty }
}

enum DayEngine {
    // MARK: - Day bucketing

    /// Entries grouped to the calendar day of `date`.
    static func entries(_ all: [LogEntry], on date: Date, customFoods: [CustomFood], calendar: Calendar = .current) -> [ResolvedEntry] {
        all.filter { calendar.isDate($0.loggedAt, inSameDayAs: date) }
            .sorted { $0.loggedAt < $1.loggedAt }
            .map { EntryResolver.resolve($0, customFoods: customFoods) }
    }

    static func total(_ all: [LogEntry], on date: Date, customFoods: [CustomFood], calendar: Calendar = .current) -> Int {
        entries(all, on: date, customFoods: customFoods, calendar: calendar)
            .reduce(0) { $0 + $1.totalMg }
    }

    /// The date `offset` days from today's start of day (offset ≤ 0 for past).
    static func day(offset: Int, from today: Date = .now, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: today)) ?? today
    }

    // MARK: - Streak

    /// Consecutive days with at least one entry, counting back from today.
    /// A quiet today does not break the streak (yesterday's chain still counts).
    static func streak(_ all: [LogEntry], today: Date = .now, calendar: Calendar = .current) -> Int {
        let loggedDays = Set(all.map { calendar.startOfDay(for: $0.loggedAt) })
        var count = 0
        var cursor = calendar.startOfDay(for: today)
        if !loggedDays.contains(cursor) {
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = previous
        }
        while loggedDays.contains(cursor) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return count
    }

    // MARK: - Week stats

    struct WeekStats {
        let dayTotals: [Int]      // 7 values, oldest → newest
        let dayDates: [Date]
        let average: Double
        let underCount: Int       // days ≤ goal
        let lightestDate: Date?   // among fully elapsed days
    }

    /// Stats for the 7 days ending at `endOffset` days from today (0 = this week).
    static func week(_ all: [LogEntry], customFoods: [CustomFood], goal: Int, endOffset: Int = 0, today: Date = .now, calendar: Calendar = .current) -> WeekStats {
        let offsets = ((endOffset - 6)...endOffset)
        let dates = offsets.map { day(offset: $0, from: today, calendar: calendar) }
        let totals = dates.map { total(all, on: $0, customFoods: customFoods, calendar: calendar) }
        let avg = Double(totals.reduce(0, +)) / 7
        let under = totals.filter { $0 <= goal }.count

        // "Lightest day" excludes today (it is still in progress).
        let elapsed = zip(dates, totals).filter { !calendar.isDate($0.0, inSameDayAs: today) }
        let lightest = elapsed.min { $0.1 < $1.1 }?.0
        return WeekStats(dayTotals: totals, dayDates: dates, average: avg, underCount: under, lightestDate: lightest)
    }

    /// Percent change of this week's average vs last week's. Nil when last week
    /// has no data to compare against.
    static func weekDelta(thisAvg: Double, lastAvg: Double) -> Int? {
        guard lastAvg > 0 else { return nil }
        return Int(((thisAvg - lastAvg) / lastAvg * 100).rounded())
    }

    // MARK: - Search

    /// Live search: substring filter, prefix matches first, then mg descending.
    static func search(_ query: String, builtIn: [FoodItem], custom: [CustomFood]) -> [FoodItem] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return [] }
        let pool = custom.map(\.asFoodItem) + builtIn
        return pool
            .filter { $0.name.lowercased().contains(q) }
            .sorted { a, b in
                let ap = a.name.lowercased().hasPrefix(q)
                let bp = b.name.lowercased().hasPrefix(q)
                if ap != bp { return ap }
                return a.mg > b.mg
            }
    }

    /// The browse shelf: bands by sodium, highest first (as in the design).
    static func shelfBands(_ builtIn: [FoodItem]) -> [(label: String, rows: [FoodItem])] {
        func band(_ lo: Int, _ hi: Int) -> [FoodItem] {
            builtIn.filter { $0.mg >= lo && $0.mg < hi }.sorted { $0.mg > $1.mg }
        }
        return [
            ("SALT BOMBS · 800 MG AND UP", band(800, .max)),
            ("MIDDLE SHELF · 300–799 MG", band(300, 800)),
            ("LIGHT TOUCH · UNDER 300 MG", band(0, 300)),
        ]
    }
}

// MARK: - Badges

struct BadgeState: Identifiable {
    let id: String
    let name: String
    let detail: String
    let iconPath: String   // empty when the medallion shows a number instead
    let iconText: String
    let earnedDate: Date?
    let progressNote: String?  // e.g. "3 of 5 so far" when unearned

    var earned: Bool { earnedDate != nil }
}

enum BadgeEngine {
    /// Derives all six badges from the log.
    static func badges(
        entries: [LogEntry],
        customFoods: [CustomFood],
        lookupCount: Int,
        sleuthEarnedAt: Date?,
        streak: Int,
        today: Date = .now,
        calendar: Calendar = .current
    ) -> [BadgeState] {
        let loggedDays = Set(entries.map { calendar.startOfDay(for: $0.loggedAt) }).sorted()
        let firstDay = loggedDays.first

        /// Day the streak ending today first reached `length`.
        func streakReached(_ length: Int) -> Date? {
            guard streak >= length else { return nil }
            var cursor = calendar.startOfDay(for: today)
            if !loggedDays.contains(cursor), let previous = calendar.date(byAdding: .day, value: -1, to: cursor) {
                cursor = previous
            }
            // Walk back to the start of the current streak, then forward length-1 days.
            var start = cursor
            while let previous = calendar.date(byAdding: .day, value: -1, to: start),
                  loggedDays.contains(previous) {
                start = previous
            }
            return calendar.date(byAdding: .day, value: length - 1, to: start)
        }

        let coolDays = loggedDays.filter { day in
            let dayEntries = entries.filter { calendar.isDate($0.loggedAt, inSameDayAs: day) }
            let total = dayEntries.reduce(0) {
                $0 + EntryResolver.resolve($1, customFoods: customFoods).totalMg
            }
            return total > 0 && total < 1500
        }
        let coolCount = coolDays.count

        let firstPath = "M8 6 C8 3.8 8.8 3 10 3 C11.2 3 12 3.8 12 6 L12 6.8 L8 6.8 Z M7.5 8.5 C7.5 8 8.5 7.8 10 7.8 C11.5 7.8 12.5 8 12.5 8.5 L12.8 13.5 C12.9 15.5 11.7 16.8 10 16.8 C8.3 16.8 7.1 15.5 7.2 13.5 Z"
        let sleuthPath = "M13 13 L17 17 M4 9 A5 5 0 1 0 14 9 A5 5 0 1 0 4 9"
        let cucumberPath = "M4.5 15.5 C4.5 8.5 9.5 4.5 15.5 4.5 C15.5 11.5 11 15.5 4.5 15.5 Z M4.5 15.5 C7.5 11.5 9.5 9.5 12.5 7.5"

        return [
            BadgeState(
                id: "first", name: "First Pinch", detail: "Logged your very first food",
                iconPath: firstPath, iconText: "",
                earnedDate: firstDay, progressNote: firstDay == nil ? "Log a food to earn" : nil
            ),
            BadgeState(
                id: "hat", name: "Hat Trick", detail: "A 3-day logging streak",
                iconPath: "", iconText: "3",
                earnedDate: streakReached(3),
                progressNote: streak >= 3 ? nil : "\(3 - streak) day\(3 - streak == 1 ? "" : "s") to go"
            ),
            BadgeState(
                id: "sleuth", name: "Label Sleuth", detail: "Looked up 25 foods",
                iconPath: sleuthPath, iconText: "",
                earnedDate: sleuthEarnedAt,
                progressNote: sleuthEarnedAt == nil ? "\(min(lookupCount, 25)) of 25 so far" : nil
            ),
            BadgeState(
                id: "week", name: "Salt Week", detail: "A 7-day logging streak",
                iconPath: "", iconText: "7",
                earnedDate: streakReached(7),
                progressNote: streak >= 7 ? nil : "\(7 - streak) day\(7 - streak == 1 ? "" : "s") to go"
            ),
            BadgeState(
                id: "cool", name: "Cool Cucumber", detail: "5 days under 1,500 mg",
                iconPath: cucumberPath, iconText: "",
                earnedDate: coolCount >= 5 ? coolDays.dropFirst(4).first : nil,
                progressNote: coolCount >= 5 ? nil : "\(coolCount) of 5 so far"
            ),
            BadgeState(
                id: "steady", name: "Steady Shaker", detail: "A 30-day logging streak",
                iconPath: "", iconText: "30",
                earnedDate: streakReached(30),
                progressNote: streak >= 30 ? nil : "\(30 - streak) to go"
            ),
        ]
    }
}
