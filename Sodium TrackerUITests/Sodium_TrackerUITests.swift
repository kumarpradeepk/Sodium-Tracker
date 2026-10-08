//
//  Sodium_TrackerUITests.swift
//  Sodium TrackerUITests
//
//  Created by pradeep.kumar1 on 01/08/26.
//

import XCTest

final class Sodium_TrackerUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    /// Walks the complete first-run journey and the four primary destinations.
    /// Keeping this as a UI smoke test makes the visual parity audit repeatable.
    @MainActor
    func testParityAuditFlow() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-hasOnboarded", "NO"]
        app.launch()

        // The launch choreography intentionally covers the app for several
        // seconds while the underlying onboarding tree is already accessible.
        // Wait for the visible splash to leave before sending the first tap.
        Thread.sleep(forTimeInterval: 10)

        XCTAssertTrue(app.staticTexts["Meet Pinch"].waitForExistence(timeout: 15))
        capture(app, "01-onboarding-welcome")

        tap("Nice to meet you", in: app)
        captureAfterWaiting(app, text: "Why count sodium?", name: "02-onboarding-why")
        tap("Doctor recommended", in: app)
        tap("Continue", in: app)

        captureAfterWaiting(app, text: "How’s the plate lately?", name: "03-onboarding-diet")
        tap("Somewhere in the middle", in: app)
        tap("Continue", in: app)

        captureAfterWaiting(app, text: "Set your salt budget", name: "04-onboarding-budget")
        tap("Set 1,500 mg budget", in: app)

        captureAfterWaiting(app, text: "Meal check-ins", name: "05-onboarding-checkins")
        tap("Save check-ins", in: app)

        captureAfterWaiting(app, text: "Any label works", name: "06-onboarding-label-units")
        tap("Continue", in: app)

        captureAfterWaiting(app, text: "Make logging easy", name: "07-onboarding-fast-logging")
        tap("Got it", in: app)

        captureAfterWaiting(app, text: "You’re all set", name: "08-onboarding-summary")
        tap("Open my tracker", in: app)

        XCTAssertTrue(app.buttons["Log a food"].waitForExistence(timeout: 5))
        capture(app, "10-today")
        app.buttons["Log a food"].tap()
        captureAfterWaiting(app, text: "QUICK ADD", name: "11-quick-add")
        app.buttons["Close add menu"].tap()

        tap("Trends", in: app)
        captureAfterWaiting(app, text: "THE LONG GAME", name: "12-trends")
        tap("Rhythm", in: app)
        captureAfterWaiting(app, text: "Your rhythm", name: "13-rhythm")
        tap("Settings", in: app)
        captureAfterWaiting(app, text: "YOUR SETUP", name: "14-settings")
    }

    /// Guards the App Review requirement that both legal destinations are
    /// presented directly in the subscription purchase flow.
    @MainActor
    func testPaywallShowsLegalLinks() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-hasOnboarded", "YES"]
        app.launch()

        tap("Settings", in: app)
        tap("See what’s inside", in: app)

        XCTAssertTrue(app.staticTexts["Pinch Plus"].waitForExistence(timeout: 5))
        app.swipeUp()
        let privacyPolicy = app.descendants(matching: .any)["Privacy Policy"].firstMatch
        let termsOfUse = app.descendants(matching: .any)["Terms of Use"].firstMatch
        XCTAssertTrue(privacyPolicy.waitForExistence(timeout: 3))
        XCTAssertTrue(termsOfUse.waitForExistence(timeout: 3))
        capture(app, "paywall-legal-links")
        let monthly = app.buttons["paywall.monthly"]
        XCTAssertTrue(monthly.exists)
        monthly.tap()
        XCTAssertFalse(app.staticTexts["Try Plus free for 3 days"].exists)
        XCTAssertFalse(app.switches["Remind me before the trial ends"].exists)
        XCTAssertTrue(privacyPolicy.isHittable)
        XCTAssertTrue(termsOfUse.isHittable)
        capture(app, "paywall-monthly-no-trial")
    }

    @MainActor
    func testNotificationPrimerFourVariantsAndDismissal() throws {
        for variant in ["firstLog", "routine", "history", "control"] {
            let app = XCUIApplication()
            app.launchArguments += ["-hasOnboarded", "YES", "-notificationPrimerPreview", variant,
                                    "-pinch.notificationPrimer.optOut", "YES"]
            app.launch()
            let notNow = app.buttons["notification-primer.not-now"]
            if !notNow.waitForExistence(timeout: 8) || !notNow.isHittable { app.swipeUp() }
            XCTAssertTrue(notNow.waitForExistence(timeout: 3))
            XCTAssertFalse(app.alerts.firstMatch.exists, "The primer must not trigger Apple's permission alert")
            capture(app, "notification-primer-\(variant)")
            notNow.tap()
            XCTAssertTrue(app.buttons["Log a food"].waitForExistence(timeout: 5))
            XCTAssertFalse(app.alerts.firstMatch.exists)
            app.terminate()
        }
    }

    /// The center FAB must lead to the complete logging flow, not strand users
    /// with only the three suggested quick-add amounts.
    @MainActor
    func testFabOpensFullFoodLog() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-hasOnboarded", "YES"]
        app.launch()

        XCTAssertTrue(app.buttons["Log a food"].waitForExistence(timeout: 12))
        app.buttons["Log a food"].tap()

        XCTAssertTrue(app.staticTexts["QUICK ADD"].waitForExistence(timeout: 5))
        let fullLog = app.buttons["Open full food log"]
        XCTAssertTrue(fullLog.waitForExistence(timeout: 5))
        XCTAssertLessThan(fullLog.frame.maxY, app.buttons["Close add menu"].frame.minY,
                          "The quick-add card must stay clear of the dock.")
        capture(app, "fab-quick-add-redesign")
        fullLog.tap()

        capture(app, "fab-after-full-log-tap")
        // The focused shelf search field is the authoritative signal that the
        // full LogSheet replaced the lightweight quick-add menu.
        XCTAssertTrue(app.textFields.firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(fullLog.exists)
        capture(app, "fab-full-food-log")

        XCTAssertFalse(app.buttons["Close add menu"].exists)
        let closeSheet = app.buttons["Close"]
        XCTAssertTrue(closeSheet.waitForExistence(timeout: 5))
        closeSheet.tap()
        XCTAssertTrue(app.buttons["Log a food"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.textFields.firstMatch.exists)
    }

    @MainActor
    func testPortionConfirmationIsNotCoveredByDock() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-hasOnboarded", "YES", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        XCTAssertTrue(app.buttons["Log a food"].waitForExistence(timeout: 12))
        app.buttons["Log a food"].tap()
        app.buttons["Open full food log"].tap()
        let food = app.buttons.containing(.staticText, identifier: "Instant ramen").firstMatch
        XCTAssertTrue(food.waitForExistence(timeout: 5))
        food.tap()
        let add = app.buttons["Add 1,560 mg"]
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        capture(app, "portion-confirmation")
        XCTAssertFalse(app.buttons["Close add menu"].isHittable,
                       "The dock must not cover the confirmation or open another dialog.")
        XCTAssertTrue(add.isHittable)
        add.tap()
        XCTAssertTrue(app.buttons["Log a food"].waitForExistence(timeout: 5))
        XCTAssertFalse(add.exists)
        XCTAssertTrue(app.staticTexts["Instant ramen, 1,560 mg"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testManualLogConfirmationIsNotCoveredByDock() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-hasOnboarded", "YES", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        XCTAssertTrue(app.buttons["Log a food"].waitForExistence(timeout: 12))
        app.buttons["Log a food"].tap()
        app.buttons["Open full food log"].tap()
        let quickLog = app.buttons["Quick\nlog"]
        XCTAssertTrue(quickLog.waitForExistence(timeout: 5))
        quickLog.tap()
        let name = app.textFields.matching(NSPredicate(format: "placeholderValue == %@", "e.g. Diner omelette")).firstMatch
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("FAB verification")
        let amount = app.textFields.matching(NSPredicate(format: "placeholderValue == %@", "0")).firstMatch
        amount.tap()
        amount.typeText("123")
        let confirm = app.buttons["Log it"]
        XCTAssertTrue(confirm.isHittable)
        capture(app, "manual-log-confirmation")
        XCTAssertFalse(app.buttons["dock-add-button"].isHittable)
        confirm.tap()
        XCTAssertTrue(app.buttons["Log a food"].waitForExistence(timeout: 5))
        XCTAssertFalse(confirm.exists)
        XCTAssertTrue(app.staticTexts["FAB verification, 123 mg"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testNewFoodConfirmationIsNotCoveredByDock() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-hasOnboarded", "YES", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        XCTAssertTrue(app.buttons["Log a food"].waitForExistence(timeout: 12))
        app.buttons["Log a food"].tap()
        app.buttons["Open full food log"].tap()
        let newFood = app.buttons["New\nfood"]
        XCTAssertTrue(newFood.waitForExistence(timeout: 5))
        newFood.tap()
        let name = app.textFields.matching(NSPredicate(format: "placeholderValue == %@", "e.g. Mom's marinara")).firstMatch
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("FAB shelf verification")
        let amount = app.textFields.matching(NSPredicate(format: "placeholderValue == %@", "0")).firstMatch
        amount.tap()
        amount.typeText("125")
        let confirm = app.buttons["Add to my shelf"]
        XCTAssertTrue(confirm.isHittable)
        XCTAssertFalse(app.buttons["dock-add-button"].isHittable)
        capture(app, "new-food-confirmation")
        // Cancel this layout fixture so repeated runs do not fill the free shelf.
        let closeButtons = app.buttons.matching(identifier: "Close")
        XCTAssertGreaterThan(closeButtons.count, 0)
        closeButtons.element(boundBy: closeButtons.count - 1).tap()
        XCTAssertFalse(confirm.exists)
    }

    @MainActor
    func testQuickAddAppearanceVariants() throws {
        for (theme, language, locale, openLabel, fullLogLabel, closeLabel) in [
            ("light", "en", "en_US", "Log a food", "Open full food log", "Close add menu"),
            ("dark", "en", "en_US", "Log a food", "Open full food log", "Close add menu"),
            ("light", "de", "de_DE", "Lebensmittel protokollieren", "Lebensmittelprotokoll öffnen", "Hinzufügen schließen")
        ] {
            let app = XCUIApplication()
            app.launchArguments += ["-hasOnboarded", "YES", "-theme", theme,
                                    "-AppleLanguages", "(\(language))", "-AppleLocale", locale]
            app.launch()
            XCTAssertTrue(app.buttons[openLabel].waitForExistence(timeout: 12))
            app.scrollViews.firstMatch.swipeUp()
            app.buttons[openLabel].tap()
            let fullLog = app.buttons[fullLogLabel]
            XCTAssertTrue(fullLog.waitForExistence(timeout: 5))
            XCTAssertTrue(fullLog.isHittable)
            XCTAssertGreaterThanOrEqual(fullLog.frame.minX, 20)
            XCTAssertLessThanOrEqual(fullLog.frame.maxX, app.frame.maxX - 20)
            XCTAssertLessThan(fullLog.frame.maxY, app.buttons[closeLabel].frame.minY)
            capture(app, "fab-\(theme)-\(language)-scrolled")
            app.buttons[closeLabel].tap()
            XCTAssertFalse(fullLog.exists)
            app.terminate()
        }
    }

    @MainActor
    private func tap(_ label: String, in app: XCUIApplication) {
        let element = app.descendants(matching: .any)[label].firstMatch
        XCTAssertTrue(element.waitForExistence(timeout: 5), "Missing UI element: \(label)")
        element.tap()
    }

    @MainActor
    private func tap(prefix: String, in app: XCUIApplication) {
        let element = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@", prefix))
            .firstMatch
        XCTAssertTrue(element.waitForExistence(timeout: 5), "Missing UI element beginning with: \(prefix)")
        element.tap()
    }

    @MainActor
    private func captureAfterWaiting(_ app: XCUIApplication, text: String, name: String) {
        XCTAssertTrue(app.staticTexts[text].waitForExistence(timeout: 5), "Missing screen marker: \(text)")
        capture(app, name)
    }

    @MainActor
    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testLiveFatSecretSearchAndMainScreens() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-hasOnboarded", "YES", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        XCTAssertTrue(app.buttons["Log a food"].waitForExistence(timeout: 15))
        capture(app, "audit-today")
        app.buttons["Log a food"].tap()
        capture(app, "audit-recommendations")
        app.buttons["Open full food log"].tap()
        let search = app.textFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("idli")
        let remote = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "fatsecret-food-")).firstMatch
        XCTAssertTrue(remote.waitForExistence(timeout: 25), "A food absent from the built-in catalog must return live FatSecret results.")
        XCTAssertTrue(app.staticTexts["FROM FATSECRET"].exists)
        capture(app, "audit-live-fatsecret-idli")
        app.buttons["Clear"].tap()
        search.typeText("avocado")
        XCTAssertTrue(remote.waitForExistence(timeout: 25))
        XCTAssertTrue(app.buttons.containing(.staticText, identifier: "Avocado").firstMatch.waitForExistence(timeout: 25))
        capture(app, "audit-live-fatsecret-avocado")
        app.buttons["Close"].tap()
        XCTAssertTrue(app.buttons["dock-add-button"].waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 1)
        for (tab, heading) in [("Trends", "THE LONG GAME"), ("Rhythm", "Your rhythm"), ("Settings", "YOUR SETUP")] {
            app.buttons[tab].tap()
            XCTAssertTrue(app.staticTexts[heading].waitForExistence(timeout: 5))
            capture(app, "audit-\(tab.lowercased())")
            app.swipeUp()
            capture(app, "audit-\(tab.lowercased())-lower")
        }
    }

    @MainActor
    func testFavoriteRecommendationsStayInSync() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-hasOnboarded", "YES", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        XCTAssertTrue(app.buttons["Log a food"].waitForExistence(timeout: 15))
        app.buttons["Log a food"].tap()
        app.buttons["Open full food log"].tap()
        let localFood = app.buttons.containing(.staticText, identifier: "Pepperoni pizza").firstMatch
        XCTAssertTrue(localFood.waitForExistence(timeout: 5))
        localFood.tap()
        let pin = app.buttons["Pin to favorites"]
        if pin.waitForExistence(timeout: 2) { pin.tap() }
        app.buttons["Add 683 mg"].tap()
        XCTAssertTrue(app.buttons["Log a food"].waitForExistence(timeout: 5))
        app.buttons["Log a food"].tap()
        let quick = app.buttons["quick-recommendation-piz"]
        XCTAssertTrue(quick.waitForExistence(timeout: 5))
        XCTAssertEqual(quick.value as? String, "Favorite")
        capture(app, "audit-favorite-quick-add")
        quick.tap()
        XCTAssertTrue(app.staticTexts["Pepperoni pizza, 683 mg"].waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 1)
        app.swipeUp()
        let today = app.buttons["today-recommendation-piz"]
        XCTAssertTrue(today.waitForExistence(timeout: 5))
        XCTAssertEqual(today.value as? String, "Favorite")
        capture(app, "audit-favorite-today-and-real-log")
        let again = app.buttons["Log Pepperoni pizza again today"].firstMatch
        if again.isHittable {
            again.tap()
            XCTAssertFalse(app.staticTexts["Track the essentials. Plus adds the extras."].exists,
                           "Repeating a built-in food must not trigger the remote-food paywall.")
        }
    }

    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
