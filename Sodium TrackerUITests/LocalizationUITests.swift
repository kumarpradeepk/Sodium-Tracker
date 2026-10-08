import XCTest

final class LocalizationUITests: XCTestCase {
    @MainActor
    func testLocalizedPrimaryScreensAndPaywall() throws {
        continueAfterFailure = false
        let languages = ["en", "de", "ja", "fr", "nl", "it", "es", "sv", "zh-Hans", "ms", "ta", "ga", "mi", "rm"]
        for language in languages {
            let app = XCUIApplication()
            app.launchArguments = ["-hasOnboarded", "YES", "-pinch.language", language,
                                   "-pinch.notificationPrimer.optOut", "YES"]
            app.launch()
            let today = app.buttons["dock-tab-today"]
            XCTAssertTrue(today.waitForExistence(timeout: 15), language)
            for screen in ["today", "trends", "awards", "settings"] {
                let tab = app.buttons["dock-tab-\(screen)"]
                XCTAssertTrue(tab.waitForExistence(timeout: 5))
                tab.tap()
                capture(app, "\(language)-\(screen)")
            }
            let plus = app.buttons["settings.paywall"]
            XCTAssertTrue(plus.waitForExistence(timeout: 5))
            plus.tap()
            XCTAssertTrue(app.buttons["paywall.yearly"].waitForExistence(timeout: 5))
            capture(app, "\(language)-paywall-top")
            // Long translations must remain scrollable rather than clipped.
            for _ in 0..<4 where !app.buttons["paywall.monthly"].isHittable { app.swipeUp() }
            XCTAssertTrue(app.buttons["paywall.monthly"].isHittable, language)
            app.buttons["paywall.monthly"].tap()
            capture(app, "\(language)-paywall-monthly")
            let terms = app.descendants(matching: .any)["paywall.terms"].firstMatch
            let privacy = app.descendants(matching: .any)["paywall.privacy"].firstMatch
            for _ in 0..<5 where !terms.isHittable { app.swipeUp() }
            XCTAssertTrue(terms.isHittable, language)
            XCTAssertTrue(privacy.isHittable, language)
            XCTAssertTrue(app.buttons["paywall.restore"].isHittable, language)
            capture(app, "\(language)-paywall-legal")
            app.terminate()
        }
    }

    @MainActor
    func testNotificationPrimerInEveryLanguage() throws {
        for language in ["en", "de", "ja", "fr", "nl", "it", "es", "sv", "zh-Hans", "ms", "ta", "ga", "mi", "rm"] {
            let app = XCUIApplication()
            app.launchArguments = ["-hasOnboarded", "YES", "-pinch.language", language,
                                   "-notificationPrimerPreview", "firstLog", "-pinch.notificationPrimer.optOut", "YES"]
            app.launch()
            XCTAssertTrue(app.buttons["notification-primer.continue"].waitForExistence(timeout: 15))
            let title = app.staticTexts["notification-primer.title"].label
            XCTAssertFalse(title.isEmpty, language)
            if language != "en" {
                XCTAssertNotEqual(title, "One less thing to remember", language)
                XCTAssertNotEqual(app.buttons["notification-primer.not-now"].label, "Not now", language)
            }
            for _ in 0..<3 where !app.buttons["notification-primer.not-now"].isHittable { app.swipeUp() }
            XCTAssertTrue(app.buttons["notification-primer.not-now"].isHittable, language)
            XCTAssertFalse(app.alerts.firstMatch.exists)
            capture(app, "\(language)-notification-primer")
            app.buttons["notification-primer.not-now"].tap()
            app.terminate()
        }
    }

    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = name
        image.lifetime = .keepAlways
        add(image)
    }
}
