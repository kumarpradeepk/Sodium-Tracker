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
    static let trialReminderPreference = "pinch.plus.trialReminder"
    private static let trialReminderID = "pinch.plus.trialReminder.notification"

    /// Call only from the explanatory sheet's Continue button.
    static func requestPermissionAfterExplanation() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }

    static func isAuthorized() async -> Bool {
        let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        return status == .authorized || status == .provisional || status == .ephemeral
    }

    /// Schedule only from a verified trial purchase, never from tapping the CTA.
    /// Forty-eight hours of notice leaves time before Apple's cancellation deadline.
    static func scheduleTrialReminder(expiresAt: Date) async {
        guard UserDefaults.standard.bool(forKey: trialReminderPreference) else { return }
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }
        let fireDate = expiresAt.addingTimeInterval(-48 * 60 * 60)
        guard fireDate.timeIntervalSinceNow > 1 else { return }
        let content = UNMutableNotificationContent()
        content.title = PinchLocalization.resolve("Your Pinch Plus trial")
        content.body = PinchLocalization.resolve("Your trial ends in about two days. To avoid renewal, cancel at least 24 hours before it ends in Apple subscription settings.")
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: fireDate.timeIntervalSinceNow, repeats: false)
        try? await center.add(UNNotificationRequest(identifier: trialReminderID, content: content, trigger: trigger))
    }

    struct MealTime {
        let meal: String
        let hour: Int
        let minute: Int
        let defaultsKey: String
    }

    static func refreshTrialLanguage() async {
        let center = UNUserNotificationCenter.current()
        guard let existing = await center.pendingNotificationRequests().first(where: { $0.identifier == trialReminderID }),
              let content = existing.content.mutableCopy() as? UNMutableNotificationContent else { return }
        content.title = PinchLocalization.resolve("Your Pinch Plus trial")
        content.body = PinchLocalization.resolve("Your trial ends in about two days. To avoid renewal, cancel at least 24 hours before it ends in Apple subscription settings.")
        // Preserve the original fire date: do not restart an interval on language change.
        let nextDate = (existing.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate()
            ?? (existing.trigger as? UNTimeIntervalNotificationTrigger)?.nextTriggerDate()
        guard let date = nextDate, date > .now else { return }
        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date), repeats: false)
        try? await center.add(UNNotificationRequest(identifier: trialReminderID, content: content, trigger: trigger))
    }

    /// Design times: Breakfast 8:00 AM, Lunch 12:30 PM, Dinner 6:30 PM.
    static let mealTimes: [MealTime] = [
        MealTime(meal: "Breakfast", hour: 8, minute: 0, defaultsKey: PinchDefaults.mealRemBreakfast),
        MealTime(meal: "Lunch", hour: 12, minute: 30, defaultsKey: PinchDefaults.mealRemLunch),
        MealTime(meal: "Dinner", hour: 18, minute: 30, defaultsKey: PinchDefaults.mealRemDinner),
    ]

    static func displayTime(_ t: MealTime) -> String {
        PinchFormat.clock(hour: t.hour, minute: t.minute)
    }

    private static func body(for meal: String, remaining: Int) -> String {
        // Repeating notifications cannot know tomorrow's remaining intake.
        // Never freeze today's number into a message repeated indefinitely.
        switch meal {
        case "Breakfast":
            return PinchLocalization.resolve("Morning check-in — log breakfast when you’re ready.")
        case "Lunch":
            return PinchLocalization.resolve("Lunch check-in — open Pinch to log your meal and see today’s total.")
        default:
            return PinchLocalization.resolve("Dinner check-in — a moment to log your meal and review your day.")
        }
    }

    /// Scheduling must NEVER trigger consent UI, including at launch.
    static func refresh(remaining: Int, defaults: UserDefaults = .standard) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(
            withIdentifiers: mealTimes.map { "pinch.checkin.\($0.meal)" }
        )
        guard defaults.bool(forKey: PinchDefaults.notif) else { return }

        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional,
                  defaults.bool(forKey: PinchDefaults.notif) else { return }
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
