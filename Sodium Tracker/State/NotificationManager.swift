//
//  NotificationManager.swift
//  Sodium Tracker
//
//  Meal check-in notifications. One gentle wave per enabled meal, daily.
//  Copy follows the design: never guilt.
//

import Foundation
import UserNotifications

enum NotificationManager {
    struct MealTime {
        let meal: String
        let hour: Int
        let minute: Int
        let defaultsKey: String
    }

    /// Design times: Breakfast 8:00 AM, Lunch 12:30 PM, Dinner 6:30 PM.
    static let mealTimes: [MealTime] = [
        MealTime(meal: "Breakfast", hour: 8, minute: 0, defaultsKey: PinchDefaults.mealRemBreakfast),
        MealTime(meal: "Lunch", hour: 12, minute: 30, defaultsKey: PinchDefaults.mealRemLunch),
        MealTime(meal: "Dinner", hour: 18, minute: 30, defaultsKey: PinchDefaults.mealRemDinner),
    ]

    static func displayTime(_ t: MealTime) -> String {
        let h12 = t.hour % 12 == 0 ? 12 : t.hour % 12
        let suffix = t.hour < 12 ? "AM" : "PM"
        return String(format: "%d:%02d %@", h12, t.minute, suffix)
    }

    private static func body(for meal: String, remaining: Int) -> String {
        let mg = PinchFormat.mg(max(0, remaining))
        switch meal {
        case "Breakfast":
            return "Morning check-in — a fresh page, \(mg) mg to play with. Log breakfast when you’re ready."
        case "Lunch":
            return "Lunch check-in — \(mg) mg still in the budget. Keeping count together."
        default:
            return "Dinner check-in — \(mg) mg still in the budget. Soup counts, I’m keeping track."
        }
    }

    /// Re-schedules everything from current preferences. Requests permission the
    /// first time check-ins are enabled; quietly does nothing if denied.
    static func refresh(remaining: Int, defaults: UserDefaults = .standard) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(
            withIdentifiers: mealTimes.map { "pinch.checkin.\($0.meal)" }
        )
        guard defaults.bool(forKey: PinchDefaults.notif) else { return }

        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            for time in mealTimes where defaults.bool(forKey: time.defaultsKey) {
                let content = UNMutableNotificationContent()
                content.title = "Pinch"
                content.body = body(for: time.meal, remaining: remaining)
                content.sound = .default

                var components = DateComponents()
                components.hour = time.hour
                components.minute = time.minute
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let request = UNNotificationRequest(
                    identifier: "pinch.checkin.\(time.meal)",
                    content: content,
                    trigger: trigger
                )
                center.add(request)
            }
        }
    }
}
