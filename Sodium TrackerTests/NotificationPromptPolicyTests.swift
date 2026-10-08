import Testing
import Foundation
@testable import Sodium_Tracker

@MainActor
struct NotificationPromptPolicyTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func firstLaunchWaitsForOnboardingNotForAFoodLog() {
        #expect(!NotificationPromptPolicy.shouldShow(now: now, lastShown: nil, count: 0,
            optedOut: false, hasCompletedOnboarding: false, authorized: false))
        #expect(NotificationPromptPolicy.shouldShow(now: now, lastShown: nil, count: 0,
            optedOut: false, hasCompletedOnboarding: true, authorized: false))
    }
    @Test func notNowWaitsFull24Hours() {
        for elapsed in [0.0, 43_200, 86_399] {
            #expect(!NotificationPromptPolicy.shouldShow(now: now, lastShown: now.addingTimeInterval(-elapsed),
                count: 1, optedOut: false, hasCompletedOnboarding: true, authorized: false))
        }
        #expect(NotificationPromptPolicy.shouldShow(now: now, lastShown: now.addingTimeInterval(-86_400),
            count: 1, optedOut: false, hasCompletedOnboarding: true, authorized: false))
    }
    @Test func permissionAndOptOutStopInvitations() {
        #expect(!NotificationPromptPolicy.shouldShow(now: now, lastShown: nil, count: 0,
            optedOut: false, hasCompletedOnboarding: true, authorized: true))
        #expect(!NotificationPromptPolicy.shouldShow(now: now, lastShown: nil, count: 0,
            optedOut: true, hasCompletedOnboarding: true, authorized: false))
    }
    @Test func invitationsAreCapped() {
        #expect(NotificationPromptPolicy.shouldShow(now: now, lastShown: nil, count: 4,
            optedOut: false, hasCompletedOnboarding: true, authorized: false))
        #expect(!NotificationPromptPolicy.shouldShow(now: now, lastShown: nil, count: 5,
            optedOut: false, hasCompletedOnboarding: true, authorized: false))
    }
    @Test func fiveDifferentExplanationsWithoutRandomness() {
        #expect((0..<5).map(NotificationPromptPolicy.context) == [.firstLog, .routine, .history, .control, .restart])
        #expect(NotificationPromptPolicy.context(for: -1) == .firstLog)
        #expect(NotificationPromptPolicy.context(for: 100) == .restart)
    }
    @Test func presentationHistorySurvivesRelaunch() throws {
        let suite = "notification-policy-test-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        NotificationPromptPolicy.recordShown(now: now, defaults: defaults)
        let reopened = try #require(UserDefaults(suiteName: suite))
        #expect(reopened.integer(forKey: NotificationPromptPolicy.countKey) == 1)
        #expect(reopened.double(forKey: NotificationPromptPolicy.lastShownKey) == now.timeIntervalSince1970)
    }

    @Test func manualSettingsAndTrialDoNotConsumeAutomaticVariants() throws {
        let suite = "notification-manual-test-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        NotificationPromptPolicy.recordShown(now: now, isAutomatic: false, defaults: defaults)
        #expect(defaults.integer(forKey: NotificationPromptPolicy.countKey) == 0)
        #expect(defaults.double(forKey: NotificationPromptPolicy.lastShownKey) == now.timeIntervalSince1970)
    }

    @Test func samePresentationCannotBeCountedTwice() throws {
        let suite = "notification-presentation-test-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let id = UUID()
        NotificationPromptPolicy.recordShown(now: now, presentationID: id, defaults: defaults)
        NotificationPromptPolicy.recordShown(now: now.addingTimeInterval(60), presentationID: id, defaults: defaults)
        #expect(defaults.integer(forKey: NotificationPromptPolicy.countKey) == 1)
        #expect(defaults.double(forKey: NotificationPromptPolicy.lastShownKey) == now.timeIntervalSince1970)
    }
}
