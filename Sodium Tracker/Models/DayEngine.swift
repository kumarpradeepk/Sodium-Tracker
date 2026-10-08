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

enum SodiumInputUnit: String, CaseIterable {
    case sodiumMilligrams
    case saltGrams

    var fieldLabel: String {
        switch self {
        case .sodiumMilligrams: "SODIUM MG"
        case .saltGrams: "SALT G"
        }
    }
}

enum SodiumConverter {
    /// Sodium chloride is about 39.34% sodium by mass.
    static let sodiumMilligramsPerSaltGram = 393.4

    static func sodiumMilligrams(from text: String, unit: SodiumInputUnit, locale: Locale = PinchLocalization.locale) -> Int? {
        guard let normalized = normalizedNumber(text, locale: locale),
              let value = Double(normalized), value.isFinite, value > 0 else { return nil }
        let milligrams: Double
        switch unit {
        case .sodiumMilligrams: milligrams = value
        case .saltGrams: milligrams = value * sodiumMilligramsPerSaltGram
        }
        return Int(exactly: milligrams.rounded())
    }

    /// Interpret the complete input rather than removing punctuation while the
    /// user types. Otherwise pasting "1.234,5" can silently become "1.2345".
    /// Locale-valid grouping wins; a single comma/point is also accepted as a
    /// decimal separator when it cannot be valid grouping (e.g. "1,5" in English).
    private static func normalizedNumber(_ text: String, locale: Locale) -> String? {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        let decimal = formatter.decimalSeparator ?? "."
        let grouping = formatter.groupingSeparator ?? ","
        let primarySize = max(formatter.groupingSize, 1)
        let secondarySize = formatter.secondaryGroupingSize > 0 ? formatter.secondaryGroupingSize : primarySize

        var input = ""
        for character in text.trimmingCharacters(in: .whitespacesAndNewlines) {
            // isNumber alone includes fractions and superscripts. Only decimal
            // digits can be normalized without changing the represented value.
            if character.unicodeScalars.allSatisfy({ CharacterSet.decimalDigits.contains($0) }),
               let digit = character.wholeNumberValue, (0...9).contains(digit) {
                input += String(digit)
            } else {
                input.append(character)
            }
        }
        guard !input.isEmpty else { return nil }

        // French uses a narrow no-break space and Swiss locales an apostrophe.
        // Accept their typographic variants, but never erase arbitrary whitespace.
        let spaces = [" ", "\u{00A0}", "\u{202F}"]
        if spaces.contains(grouping) {
            for space in spaces { input = input.replacingOccurrences(of: space, with: grouping) }
        } else if grouping == "’" || grouping == "'" {
            input = input.replacingOccurrences(of: "’", with: grouping)
                .replacingOccurrences(of: "'", with: grouping)
        }

        func digits(_ value: String) -> Bool {
            !value.isEmpty && value.utf8.allSatisfy { (48...57).contains($0) }
        }

        func parse(decimalSeparator: String, groupingSeparator: String?) -> String? {
            let parts = input.components(separatedBy: decimalSeparator)
            guard parts.count <= 2 else { return nil }
            let whole = parts[0]
            let fraction = parts.count == 2 ? parts[1] : nil
            if let fraction, !digits(fraction) { return nil }

            let integer: String
            if let groupingSeparator, !groupingSeparator.isEmpty, whole.contains(groupingSeparator) {
                let groups = whole.components(separatedBy: groupingSeparator)
                guard groups.count > 1, groups.allSatisfy(digits),
                      groups.last?.count == primarySize,
                      (1...secondarySize).contains(groups[0].count),
                      groups.dropFirst().dropLast().allSatisfy({ $0.count == secondarySize }) else { return nil }
                integer = groups.joined()
            } else if whole.isEmpty, fraction != nil {
                integer = "0"
            } else {
                guard digits(whole) else { return nil }
                integer = whole
            }
            return integer + (fraction.map { "." + $0 } ?? "")
        }

        if let result = parse(decimalSeparator: decimal, groupingSeparator: grouping) { return result }
        // Do not guess a second locale for mixed or repeated separators.
        for alternate in [".", ","] where alternate != decimal {
            if input.filter({ String($0) == alternate }).count == 1,
               let result = parse(decimalSeparator: alternate, groupingSeparator: nil) { return result }
        }
        return nil
    }

    static func saltGrams(fromSodiumMilligrams milligrams: Int) -> Double {
        Double(milligrams) / sodiumMilligramsPerSaltGram
    }
}

enum PinchDefaults {
    static let theme = "theme"                       // "light" | "dark"
    static let palette = "palette"                   // PalettePick raw: ocean | sage | iris
    static let goalChoice = "goalChoice"             // GoalChoice raw
    static let customGoal = "customGoal"             // 500...4000 step 50
    static let chatty = "chatty"                     // Pinch's chatter
    static let notif = "notif"                       // meal check-ins master
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
    static let customGoalRange = 800...3000
    static let customGoalStep = 100
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
        let loggedDays: [Bool]
        var loggedDayCount: Int { loggedDays.filter { $0 }.count }
        let average: Double
        let underCount: Int       // days ≤ goal
        let lightestDate: Date?   // among fully elapsed days
    }

    /// Stats for the 7 days ending at `endOffset` days from today (0 = this week).
    static func week(_ all: [LogEntry], customFoods: [CustomFood], goal: Int, endOffset: Int = 0, today: Date = .now, calendar: Calendar = .current) -> WeekStats {
        let offsets = ((endOffset - 6)...endOffset)
        let dates = offsets.map { day(offset: $0, from: today, calendar: calendar) }
        let totals = dates.map { total(all, on: $0, customFoods: customFoods, calendar: calendar) }
        let logged = dates.map { date in all.contains { calendar.isDate($0.loggedAt, inSameDayAs: date) } }
        let recordedTotals = zip(totals, logged).filter { $0.1 }.map { $0.0 }
        let avg = recordedTotals.isEmpty ? 0 : Double(recordedTotals.reduce(0, +)) / Double(recordedTotals.count)
        let under = recordedTotals.filter { $0 <= goal }.count

        // "Lightest day" excludes today (it is still in progress).
        let elapsed = dates.indices.filter { logged[$0] && dates[$0] < calendar.startOfDay(for: today) }
        let lightest = elapsed.min { totals[$0] < totals[$1] }.map { dates[$0] }
        return WeekStats(dayTotals: totals, dayDates: dates, loggedDays: logged, average: avg, underCount: under, lightestDate: lightest)
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
            .filter { $0.name.localizedStandardContains(q) || $0.displayName.localizedStandardContains(q) }
            .sorted { a, b in
                let ap = a.name.lowercased().hasPrefix(q) || a.displayName.lowercased().hasPrefix(q)
                let bp = b.name.lowercased().hasPrefix(q) || b.displayName.lowercased().hasPrefix(q)
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
            ("SALT BOMBS: 800 MG AND UP", band(800, .max)),
            ("MIDDLE SHELF: 300 TO 799 MG", band(300, 800)),
            ("LIGHT TOUCH: UNDER 300 MG", band(0, 300)),
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
        calendar: Calendar = .current,
        legacyCoolRule: Bool = false,
        legacyCoolEarnedAt: Date? = nil
    ) -> [BadgeState] {
        let validEntries = entries.filter { $0.loggedAt <= today }
        let loggedDays = Set(validEntries.map { calendar.startOfDay(for: $0.loggedAt) }).sorted()
        let firstDay = loggedDays.first

        /// Keep a milestone earned by a historical streak after that streak ends.
        func streakReached(_ length: Int) -> Date? {
            var count = 0
            var previous: Date?
            for date in loggedDays where date <= calendar.startOfDay(for: today) {
                let consecutive = previous.map { calendar.dateComponents([.day], from: $0, to: date).day == 1 } ?? false
                count = consecutive ? count + 1 : 1
                if count >= length { return date }
                previous = date
            }
            return nil
        }

        let coolDays = legacyCoolRule ? loggedDays.filter { day in
            let dayEntries = validEntries.filter { calendar.isDate($0.loggedAt, inSameDayAs: day) }
            let total = dayEntries.reduce(0) {
                $0 + EntryResolver.resolve($1, customFoods: customFoods).totalMg
            }
            return total > 0 && total < 1500
        } : loggedDays
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
                progressNote: streak >= 3 ? nil : PinchLocalization.format("Days remaining: {0}", [PinchLocalization.number(3 - streak)])
            ),
            BadgeState(
                id: "sleuth", name: "Label Sleuth", detail: "Looked up 25 foods",
                iconPath: sleuthPath, iconText: "",
                earnedDate: sleuthEarnedAt,
                progressNote: sleuthEarnedAt == nil ? PinchLocalization.format("{0} of 25 so far", [String(describing: min(lookupCount, 25))]) : nil
            ),
            BadgeState(
                id: "week", name: "Salt Week", detail: "A 7-day logging streak",
                iconPath: "", iconText: "7",
                earnedDate: streakReached(7),
                progressNote: streak >= 7 ? nil : PinchLocalization.format("Days remaining: {0}", [PinchLocalization.number(7 - streak)])
            ),
            BadgeState(
                id: "cool", name: "Cool Cucumber", detail: "Logged on 5 different days",
                iconPath: cucumberPath, iconText: "",
                earnedDate: legacyCoolEarnedAt ?? (coolCount >= 5 ? coolDays.dropFirst(4).first : nil),
                progressNote: coolCount >= 5 ? nil : PinchLocalization.format("{0} of 5 so far", [String(describing: coolCount)])
            ),
            BadgeState(
                id: "steady", name: "Steady Shaker", detail: "A 30-day logging streak",
                iconPath: "", iconText: "30",
                earnedDate: streakReached(30),
                progressNote: streak >= 30 ? nil : PinchLocalization.format("{0} to go", [String(describing: 30 - streak)])
            ),
        ]
    }
}
