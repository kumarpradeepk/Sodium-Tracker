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

        captureAfterWaiting(app, text: "How's the plate lately?", name: "03-onboarding-diet")
        tap("Somewhere in the middle", in: app)
        tap("Continue", in: app)

        captureAfterWaiting(app, text: "Set your salt budget", name: "04-onboarding-budget")
        tap(prefix: "Set my budget", in: app)

        captureAfterWaiting(app, text: "Meal check-ins", name: "05-onboarding-checkins")
        tap("Save check-ins", in: app)

        captureAfterWaiting(app, text: "Read either label unit", name: "06-onboarding-label-units")
        tap("Got it", in: app)

        captureAfterWaiting(app, text: "A tap on the shoulder, not a siren", name: "07-onboarding-notifications")
        tap("Maybe later", in: app)

        captureAfterWaiting(app, text: "Logging stays quick", name: "08-onboarding-fast-logging")
        tap("One more step", in: app)

        captureAfterWaiting(app, text: "You're all set", name: "09-onboarding-summary")
        tap("Start tracking", in: app)

        XCTAssertTrue(app.buttons["Quick add"].waitForExistence(timeout: 5))
        capture(app, "10-today")
        app.buttons["Quick add"].tap()
        captureAfterWaiting(app, text: "QUICK ADD", name: "11-quick-add")
        app.buttons["Quick add"].tap()

        tap("Trends", in: app)
        captureAfterWaiting(app, text: "YOUR PATTERN", name: "12-trends")
        tap("Awards", in: app)
        captureAfterWaiting(app, text: "SMALL WINS", name: "13-awards")
        tap("Settings", in: app)
        captureAfterWaiting(app, text: "YOUR SETUP", name: "14-settings")
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
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
