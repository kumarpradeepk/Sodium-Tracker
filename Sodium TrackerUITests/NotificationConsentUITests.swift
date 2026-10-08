import XCTest

/// Run on the dedicated fresh Notification Consent QA simulator. Never taps Allow.
final class NotificationConsentUITests: XCTestCase {
    @MainActor
    func testFreshLaunchFiveCopyVariantsDailyCooldownAndSystemPermissionOrder() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let base = ["-pinch.language", "en", "-mealRemBreakfast", "YES", "-mealRemDinner", "YES"]
        app.launchArguments = base
        app.launch()
        let skip = app.buttons["Skip the tour"]
        XCTAssertTrue(skip.waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons["notification-primer.continue"].exists)
        XCTAssertFalse(springboard.alerts.firstMatch.exists)
        skip.tap()

        // No food is logged: completion of onboarding must be enough.
        let next = app.buttons["notification-primer.continue"]
        let notNow = app.buttons["notification-primer.not-now"]
        XCTAssertTrue(next.waitForExistence(timeout: 10))
        XCTAssertTrue(next.isHittable)
        XCTAssertTrue(notNow.isHittable)
        XCTAssertFalse(app.buttons["notification-primer.dont-ask"].exists)
        XCTAssertFalse(app.buttons["Don't ask again"].exists)
        XCTAssertEqual(app.staticTexts["notification-primer.title"].label, "One less thing to remember")
        let titleY = app.staticTexts["notification-primer.title"].frame.minY
        let actionY = next.frame.minY
        XCTAssertFalse(springboard.alerts.firstMatch.exists)
        capture(app, "01-first-launch-explanation-before-permission")
        notNow.tap()
        XCTAssertTrue(app.buttons["dock-add-button"].waitForExistence(timeout: 5))
        app.terminate()

        // Use persisted real presentation history for the relaunch regression.
        app.launchArguments = base + ["-hasOnboarded", "YES"]
        app.launch()
        XCTAssertTrue(app.buttons["dock-add-button"].waitForExistence(timeout: 10))
        XCTAssertFalse(next.waitForExistence(timeout: 3), "Not now must survive a relaunch")
        capture(app, "02-relaunch-respects-24-hour-cooldown")
        app.terminate()

        let old = String(Date.now.addingTimeInterval(-24 * 3600 - 60).timeIntervalSince1970)
        let variants = ["A small pause for your day", "Keep the little details", "Build a rhythm that fits", "Come back when you’re ready"]
        for (index, title) in variants.enumerated() {
            app.launchArguments = base + ["-hasOnboarded", "YES", "-pinch.notificationPrimer.lastShown", old,
                "-pinch.notificationPrimer.count", String(index + 1), "-pinch.notificationPrimer.optOut", "NO"]
            app.launch()
            XCTAssertTrue(next.waitForExistence(timeout: 10))
            XCTAssertEqual(app.staticTexts["notification-primer.title"].label, title)
            XCTAssertTrue(next.isHittable)
            XCTAssertTrue(notNow.isHittable)
            XCTAssertFalse(app.buttons["Don't ask again"].exists)
            XCTAssertEqual(app.staticTexts["notification-primer.title"].frame.minY, titleY, accuracy: 1)
            XCTAssertEqual(next.frame.minY, actionY, accuracy: 1)
            XCTAssertFalse(springboard.alerts.firstMatch.exists)
            capture(app, "0\(index+3)-same-design-copy-\(index+2)")
            notNow.tap()
            app.terminate()
        }

        for (count, optedOut) in [(5, "NO"), (0, "YES")] {
            app.launchArguments = base + ["-hasOnboarded", "YES", "-pinch.notificationPrimer.lastShown", old,
                "-pinch.notificationPrimer.count", String(count), "-pinch.notificationPrimer.optOut", optedOut]
            app.launch()
            XCTAssertTrue(app.buttons["dock-add-button"].waitForExistence(timeout: 10))
            XCTAssertFalse(next.waitForExistence(timeout: 3))
            app.terminate()
        }

        // The one real OS request happens ONLY after an explicit Continue tap.
        app.launchArguments = base + ["-hasOnboarded", "YES", "-pinch.notificationPrimer.lastShown", old,
            "-pinch.notificationPrimer.count", "0", "-pinch.notificationPrimer.optOut", "NO"]
        app.launch()
        XCTAssertTrue(next.waitForExistence(timeout: 10))
        XCTAssertFalse(springboard.alerts.firstMatch.exists)
        next.tap()
        let permission = springboard.alerts.firstMatch
        XCTAssertTrue(permission.waitForExistence(timeout: 8))
        capture(springboard, "07-apple-permission-only-after-continue")
        let deny = permission.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Allow")).allElementsBoundByIndex
            .first { $0.label != "Allow" }
        XCTAssertNotNil(deny)
        deny?.tap()
        app.terminate()

        // iOS cannot show the permission alert again after denial; offer Settings.
        app.launch()
        XCTAssertTrue(next.waitForExistence(timeout: 10))
        XCTAssertTrue(next.label.contains("Open Settings"))
        XCTAssertFalse(springboard.alerts.firstMatch.exists)
        capture(app, "08-denied-permission-offers-settings")
        notNow.tap()
        app.terminate()
    }

    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
