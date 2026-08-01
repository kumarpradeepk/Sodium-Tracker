//
//  SeedData.swift
//  Sodium Tracker
//
//  First-launch seed matching the design's demo data: 14 days of entries
//  relative to today, one custom food, and two favorites.
//

import Foundation
import SwiftData

enum SeedData {
    /// (dayOffset, foodID, servings, meal, "H:mm" 24h time)
    private static let rows: [(Int, String, Double, Meal, String)] = [
        (0, "yog", 1, .breakfast, "7:58"), (0, "bagel", 1, .breakfast, "8:05"),
        (0, "bac", 1, .breakfast, "8:05"), (0, "alm", 1, .snacks, "9:15"),

        (-1, "egg", 1, .breakfast, "8:10"), (-1, "sour", 1, .breakfast, "8:10"),
        (-1, "milk", 1, .breakfast, "8:12"), (-1, "caes", 1, .lunch, "12:40"),
        (-1, "chick", 1, .dinner, "19:05"), (-1, "fries", 1, .dinner, "19:05"),
        (-1, "alm", 1, .snacks, "15:30"),

        (-2, "oat", 1, .breakfast, "7:45"), (-2, "wrap", 1, .lunch, "13:00"),
        (-2, "chip", 1, .snacks, "16:20"), (-2, "sushi", 1, .dinner, "19:30"),
        (-2, "ket", 1, .dinner, "19:30"),

        (-3, "yog", 1, .breakfast, "8:00"), (-3, "sour", 1, .breakfast, "8:00"),
        (-3, "del", 1, .lunch, "12:30"), (-3, "eda", 1, .snacks, "15:00"),
        (-3, "ched", 1, .snacks, "17:10"), (-3, "miso", 1, .dinner, "19:00"),

        (-4, "bagel", 1, .breakfast, "8:20"), (-4, "cot", 1, .breakfast, "8:20"),
        (-4, "burr", 1, .lunch, "13:10"), (-4, "pick", 1, .snacks, "16:00"),
        (-4, "tea", 1, .dinner, "18:45"),

        (-5, "egg", 1, .breakfast, "7:50"), (-5, "milk", 1, .breakfast, "7:52"),
        (-5, "burg", 1, .lunch, "12:50"), (-5, "fries", 1, .lunch, "12:50"),
        (-5, "alm", 1, .snacks, "15:40"), (-5, "caes", 1, .dinner, "19:15"),

        (-6, "yog", 1, .breakfast, "9:00"), (-6, "ram", 1, .lunch, "13:30"),
        (-6, "chip", 1, .snacks, "16:45"), (-6, "piz", 1, .dinner, "20:00"),

        (-7, "bagel", 1, .breakfast, "8:30"), (-7, "burg", 1, .lunch, "13:00"),
        (-7, "chip", 1, .lunch, "13:00"), (-7, "milk", 1, .dinner, "19:00"),

        (-8, "yog", 1, .breakfast, "8:00"), (-8, "soup", 1, .lunch, "12:30"),
        (-8, "sour", 1, .lunch, "12:30"), (-8, "pret", 1, .snacks, "16:00"),

        (-9, "sushi", 1, .dinner, "19:40"), (-9, "miso", 1, .dinner, "19:40"),
        (-9, "soy", 1, .dinner, "19:40"),

        (-10, "egg", 1, .breakfast, "8:05"), (-10, "milk", 1, .breakfast, "8:05"),
        (-10, "caes", 1, .lunch, "12:45"), (-10, "chick", 1, .lunch, "12:45"),
        (-10, "ban", 1, .snacks, "15:20"),

        (-11, "wrap", 1, .lunch, "12:55"), (-11, "chip", 1, .snacks, "16:10"),
        (-11, "piz", 1, .dinner, "19:50"), (-11, "ranch", 1, .dinner, "19:50"),

        (-12, "yog", 1, .breakfast, "8:15"), (-12, "ram", 1.5, .lunch, "13:20"),
        (-12, "eda", 1, .snacks, "16:30"),

        (-13, "oat", 1, .breakfast, "8:40"), (-13, "del", 1, .lunch, "12:35"),
        (-13, "pick", 1, .lunch, "12:35"), (-13, "cot", 1, .dinner, "18:50"),
        (-13, "tea", 1, .snacks, "15:15"),
    ]

    /// Seeds the store once. Also stamps the tracked-window start and the
    /// Label Sleuth badge state the design ships with.
    static func seedIfNeeded(context: ModelContext, defaults: UserDefaults = .standard, today: Date = .now, calendar: Calendar = .current) {
        guard !defaults.bool(forKey: PinchDefaults.hasSeeded) else { return }
        defaults.set(true, forKey: PinchDefaults.hasSeeded)

        for (offset, foodID, servings, meal, time) in rows {
            let day = DayEngine.day(offset: offset, from: today, calendar: calendar)
            let parts = time.split(separator: ":")
            let hour = Int(parts[0]) ?? 9
            let minute = parts.count > 1 ? (Int(parts[1]) ?? 0) : 0
            let stamp = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
            context.insert(LogEntry(foodID: foodID, servings: servings, meal: meal, loggedAt: stamp))
        }

        let custom = CustomFood(
            id: "cf-seed-lentil",
            name: "Nana's lentil soup",
            serving: "1 bowl",
            mg: 410,
            createdAt: DayEngine.day(offset: -5, from: today, calendar: calendar)
        )
        context.insert(custom)
        context.insert(Favorite(foodID: "yog"))
        context.insert(Favorite(foodID: "ram"))

        let start = DayEngine.day(offset: -13, from: today, calendar: calendar)
        defaults.set(start.timeIntervalSinceReferenceDate, forKey: PinchDefaults.seedStart)

        // The design ships with Label Sleuth earned 8 days ago at 25 lookups.
        defaults.set(25, forKey: PinchDefaults.lookupCount)
        let sleuthDay = DayEngine.day(offset: -8, from: today, calendar: calendar)
        defaults.set(sleuthDay.timeIntervalSinceReferenceDate, forKey: PinchDefaults.sleuthEarnedAt)

        try? context.save()
    }

    /// First day of tracked data ("before Pinch" days are dashed in the calendar).
    static func trackedStart(defaults: UserDefaults = .standard, today: Date = .now, calendar: Calendar = .current) -> Date {
        let stored = defaults.double(forKey: PinchDefaults.seedStart)
        guard stored != 0 else { return DayEngine.day(offset: -13, from: today, calendar: calendar) }
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
