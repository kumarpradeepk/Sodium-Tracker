import Foundation

struct NotificationPrompt: Identifiable {
    let id = UUID()
    let context: Context
    var isAutomatic = false
    enum Context: String, CaseIterable {
        case firstLog, routine, history, control, restart, settings, trial
    }
}

/// A reminder is an in-app invitation, not a notification sent without consent.
enum NotificationPromptPolicy {
    static let lastShownKey = "pinch.notificationPrimer.lastShown"
    static let countKey = "pinch.notificationPrimer.count"
    static let optOutKey = "pinch.notificationPrimer.optOut"
    static let presentationIDKey = "pinch.notificationPrimer.lastPresentationID"
    static let cooldown: TimeInterval = 24 * 60 * 60
    static let automaticLimit = 5

    static func shouldShow(now: Date, lastShown: Date?, count: Int, optedOut: Bool,
                           hasCompletedOnboarding: Bool, authorized: Bool) -> Bool {
        guard hasCompletedOnboarding, !authorized, !optedOut, count < automaticLimit else { return false }
        guard let lastShown else { return true }
        return now.timeIntervalSince(lastShown) >= cooldown
    }

    static func context(for count: Int) -> NotificationPrompt.Context {
        [.firstLog, .routine, .history, .control, .restart][min(max(count, 0), 4)]
    }

    static func recordShown(now: Date = .now, isAutomatic: Bool = true, presentationID: UUID = UUID(), defaults: UserDefaults = .standard) {
        // Returning from iOS Settings must not count the same sheet twice.
        guard defaults.string(forKey: presentationIDKey) != presentationID.uuidString else { return }
        defaults.set(presentationID.uuidString, forKey: presentationIDKey)
        defaults.set(now.timeIntervalSince1970, forKey: lastShownKey)
        if isAutomatic { defaults.set(defaults.integer(forKey: countKey) + 1, forKey: countKey) }
    }
}
