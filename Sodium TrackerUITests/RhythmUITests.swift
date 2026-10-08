import XCTest

final class RhythmUITests: XCTestCase {
    @MainActor
    func testRhythmAndSheetsInAllLanguages() {
        continueAfterFailure = false
        for language in ["en", "de", "ja", "fr", "nl", "it", "es", "sv", "zh-Hans", "ms", "ta", "ga", "mi", "rm"] {
            let app = XCUIApplication()
            app.launchArguments = ["-hasOnboarded", "YES", "-pinch.language", language,
                                   "-pinch.notificationPrimer.optOut", "YES"]
            app.launch()
            let tab = app.buttons["dock-tab-awards"]
            XCTAssertTrue(tab.waitForExistence(timeout: 15), language)
            tab.tap()
            XCTAssertTrue(app.staticTexts["rhythm.title"].waitForExistence(timeout: 5))
            if language != "en" { XCTAssertNotEqual(app.staticTexts["rhythm.title"].label, "Your rhythm") }
            capture(app, language + "-rhythm")
            app.buttons["rhythm.edit-goal"].tap()
            let five = app.buttons["rhythm.goal-5"]
            XCTAssertTrue(five.waitForExistence(timeout: 5))
            for _ in 0..<4 where !five.isHittable { app.swipeUp() }
            XCTAssertTrue(five.isHittable, language)
            five.tap()
            XCTAssertTrue(five.isSelected)
            capture(app, language + "-rhythm-goal")
            let close = app.buttons["rhythm.sheet.close"]
            for _ in 0..<4 where !close.isHittable { app.swipeDown() }
            close.tap()
            XCTAssertTrue(app.staticTexts["rhythm.goal-summary"].waitForExistence(timeout: 5))
            let collection = app.buttons["rhythm.collection"]
            for _ in 0..<5 where !collection.isHittable || collection.frame.maxY > app.buttons["dock-add-button"].frame.minY - 12 { app.swipeUp() }
            XCTAssertTrue(collection.isHittable, language)
            collection.tap()
            XCTAssertTrue(app.buttons["rhythm.sheet.close"].waitForExistence(timeout: 5))
            XCTAssertTrue(app.buttons["rhythm.sheet.close"].isHittable, language)
            capture(app, language + "-rhythm-collection")
            app.buttons["rhythm.sheet.close"].tap()
            XCTAssertTrue(app.buttons["rhythm.sheet.close"].waitForNonExistence(timeout: 5))
            app.terminate()
        }
    }

    @MainActor
    func testGoalPersistsAcrossRelaunchAndLogActionOpensFreshSheet() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-hasOnboarded", "YES", "-pinch.language", "en", "-pinch.notificationPrimer.optOut", "YES"]
        app.launch()
        XCTAssertTrue(app.buttons["dock-tab-awards"].waitForExistence(timeout: 15))
        app.buttons["dock-tab-awards"].tap()
        app.buttons["rhythm.edit-goal"].tap()
        XCTAssertTrue(app.buttons["rhythm.goal-4"].waitForExistence(timeout: 5))
        app.buttons["rhythm.goal-4"].tap()
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["dock-tab-awards"].waitForExistence(timeout: 15))
        app.buttons["dock-tab-awards"].tap()
        XCTAssertTrue(app.staticTexts["rhythm.goal-summary"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["rhythm.goal-summary"].label, "Your weekly logging goal: 4 days")
        // The global Add entry point must remain available on the new tab.
        app.buttons["dock-add-button"].tap()
        let full = app.buttons["quick-add.full-log"]
        XCTAssertTrue(full.waitForExistence(timeout: 5))
        full.tap()
        let search = app.textFields["food-log.search"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap(); search.typeText("oa")
        app.buttons["food-log.close"].tap()
        XCTAssertTrue(search.waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 5))
        app.buttons["dock-add-button"].tap()
        XCTAssertTrue(full.waitForExistence(timeout: 5)); full.tap()
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        XCTAssertNotEqual(search.value as? String, "oa")
        app.terminate()
    }

    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
