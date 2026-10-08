import XCTest

/// Run on a disposable simulator: this intentionally creates one reusable shelf
/// fixture and three food-log entries per language. No live food search or
/// subscription purchase is performed. Identifiers, never English UI labels,
/// drive navigation; screenshots are evidence for subsequent visual review.
final class LocalizedFlowUITests: XCTestCase {
    private let languages = [
        "en", "de", "ja", "fr", "nl", "it", "es", "sv",
        "zh-Hans", "ms", "ta", "ga", "mi", "rm"
    ]
    private let fixtureName = "Localization QA food"

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testOnboardingAndSynchronizedLoggingInEveryLanguage() throws {
        for language in languages {
            let app = XCUIApplication()
            // The existing app preference selects both copy and formatting.
            // Opting out here prevents an unrelated permission sheet from
            // interrupting this flow; the primer has its own 14-language suite.
            app.launchArguments = [
                "-hasOnboarded", "NO",
                "-pinch.language", language,
                "-pinch.notificationPrimer.optOut", "YES",
                "-theme", "light"
            ]
            app.launch()
            defer { app.terminate() }

            try completeOnboarding(app, language: language)
            try logAndFavoriteFixture(app, language: language)
            try verifyRecommendationsAndQuickAdd(app, language: language)
        }
    }

    @MainActor
    private func completeOnboarding(_ app: XCUIApplication, language: String) throws {
        let start = app.buttons["onboarding.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 15), language)
        let splash = element("launch.splash", in: app)
        if splash.exists {
            waitUntil("Splash should finish", timeout: 8) { !splash.exists }
        }
        assertReachable(start, in: app, context: "\(language) welcome")
        assertTranslated(start.label, source: "Nice to meet you", language: language)
        capture(app, "\(language)-flow-01-welcome")
        advanceOnboarding(app, button: start, language: language)

        // Verify required selections and exercise an ordinary, non-medical
        // motivation. It consistently sets the standard educational target.
        let next = app.buttons["onboarding.continue"]
        XCTAssertTrue(next.waitForExistence(timeout: 5), language)
        XCTAssertFalse(next.isEnabled, "\(language): why must require a choice")
        let why = app.buttons["onboarding.why-healthy"]
        assertReachable(why, in: app, context: "\(language) motivation")
        why.tap()
        captureStep(app, sourceTitle: "Why count sodium?", language: language, name: "02-motivation")
        advanceOnboarding(app, button: next, language: language)

        XCTAssertFalse(next.isEnabled, "\(language): diet must require a choice")
        let diet = app.buttons["onboarding.diet-mid"]
        assertReachable(diet, in: app, context: "\(language) diet")
        diet.tap()
        captureStep(app, sourceTitle: "How’s the plate lately?", language: language, name: "03-diet")
        advanceOnboarding(app, button: next, language: language)

        for (source, name) in [
            ("Set your salt budget", "04-budget"),
            ("Meal check-ins", "05-meal-checkins"),
            ("Any label works", "06-label-units"),
            ("Make logging easy", "07-fast-logging")
        ] {
            captureStep(app, sourceTitle: source, language: language, name: name)
            advanceOnboarding(app, button: next, language: language)
        }

        let finish = app.buttons["onboarding.finish"]
        assertReachable(finish, in: app, context: "\(language) onboarding finish")
        assertTranslated(finish.label, source: "Open my tracker", language: language)
        capture(app, "\(language)-flow-08-summary")
        finish.tap()
        let dock = app.buttons["dock-add-button"]
        assertReachable(dock, in: app, context: "\(language) dashboard")
        XCTAssertFalse(app.alerts.firstMatch.exists, "Onboarding must not blindly request notification consent")
    }

    @MainActor
    private func logAndFavoriteFixture(_ app: XCUIApplication, language: String) throws {
        app.buttons["dock-add-button"].tap()
        let fullLog = app.buttons["quick-add.full-log"]
        assertReachable(fullLog, in: app, context: "\(language) quick-add menu")
        XCTAssertLessThanOrEqual(fullLog.frame.maxY, app.buttons["dock-add-button"].frame.minY,
                                 "\(language): quick-add action must not overlap the center button")
        capture(app, "\(language)-flow-09-quick-add-before")

        // Pressing the open center control again should close the existing
        // menu, not create a second dialog. Reopen it once, then enter logging.
        app.buttons["dock-add-button"].tap()
        waitUntil("\(language): center button closes its menu") { !fullLog.exists }
        app.buttons["dock-add-button"].tap()
        assertReachable(fullLog, in: app, context: "\(language) reopen quick add")
        fullLog.tap()

        let quickLog = app.buttons["food-log.quick-log"]
        assertReachable(quickLog, in: app, context: "\(language) food shelf")
        capture(app, "\(language)-flow-10-food-shelf")
        quickLog.tap()

        let name = textField("quick-log.name", in: app)
        XCTAssertTrue(name.waitForExistence(timeout: 5), language)
        name.tap()
        name.typeText(fixtureName)
        let amount = textField("quick-log.amount", in: app)
        XCTAssertTrue(amount.waitForExistence(timeout: 5), language)
        amount.tap()
        amount.typeText("123")

        let favorite = element("quick-log.favorite", in: app)
        assertReachable(favorite, in: app, context: "\(language) favorite toggle")
        let oldValue = favorite.value as? String
        favorite.tap()
        waitUntil("\(language): favorite toggle changes") {
            (favorite.value as? String) != oldValue
        }

        let submit = app.buttons["quick-log.submit"]
        assertReachable(submit, in: app, context: "\(language) log confirmation with keyboard")
        XCTAssertTrue(submit.isEnabled, language)
        XCTAssertFalse(app.buttons["dock-add-button"].isHittable,
                       "\(language): underlying center button must not open another dialog")
        assertTranslated(submit.label, source: "Log it", language: language)
        capture(app, "\(language)-flow-11-manual-favorite-confirmation")
        submit.tap()
        waitUntil("\(language): manual logging dismisses its sheet") { !submit.exists }
        assertReachable(app.buttons["dock-add-button"], in: app, context: "\(language) after logging")
    }

    @MainActor
    private func verifyRecommendationsAndQuickAdd(_ app: XCUIApplication, language: String) throws {
        app.buttons["dock-add-button"].tap()
        let fullLog = app.buttons["quick-add.full-log"]
        assertReachable(fullLog, in: app, context: "\(language) recommendations after favorite")
        let recommendation = app.buttons.matching(NSPredicate(
            format: "identifier BEGINSWITH %@ AND label CONTAINS %@",
            "quick-recommendation-", fixtureName
        )).firstMatch
        assertReachable(recommendation, in: app, context: "\(language) saved food recommendation")
        let foodID = String(recommendation.identifier.dropFirst("quick-recommendation-".count))
        XCTAssertFalse(foodID.isEmpty, language)
        capture(app, "\(language)-flow-12-synced-favorite")
        recommendation.tap()
        waitUntil("\(language): quick-add closes once") { !fullLog.exists }
        assertReachable(app.buttons["dock-add-button"], in: app, context: "\(language) quick-add completion")

        // Today and the quick menu must refer to the exact saved identity,
        // not merely display unrelated foods with the same name.
        let todayRecommendation = app.buttons["today-recommendation-\(foodID)"]
        XCTAssertTrue(todayRecommendation.waitForExistence(timeout: 5),
                      "\(language): Today and quick-add recommendations must share a food ID")
        XCTAssertTrue(todayRecommendation.label.contains(fixtureName), language)
        capture(app, "\(language)-flow-13-quick-add-logged")

        // Exercise the normal portion sheet too, without typing a remote
        // search query. The fixture appears in the shared recommendation list.
        app.buttons["dock-add-button"].tap()
        assertReachable(fullLog, in: app, context: "\(language) reopen food log")
        fullLog.tap()
        let foodRow = app.buttons.matching(identifier: "food-log.item-\(foodID)").firstMatch
        assertReachable(foodRow, in: app, context: "\(language) favorite on shelf")
        foodRow.tap()
        let confirm = app.buttons["portion.confirm"]
        assertReachable(confirm, in: app, context: "\(language) portion confirmation")
        XCTAssertTrue(element("portion.favorite", in: app).exists, language)
        XCTAssertTrue(confirm.label.contains("123"), "\(language): selected portion must retain its sodium value")
        XCTAssertFalse(app.buttons["dock-add-button"].isHittable, language)
        capture(app, "\(language)-flow-14-portion-confirmation")
        confirm.tap()
        waitUntil("\(language): portion confirmation closes all logging sheets") { !confirm.exists }
        assertReachable(app.buttons["dock-add-button"], in: app, context: "\(language) completed logging")
    }

    @MainActor
    private func advanceOnboarding(_ app: XCUIApplication, button: XCUIElement, language: String) {
        let progress = element("onboarding.progress", in: app)
        XCTAssertTrue(progress.waitForExistence(timeout: 5), language)
        let oldValue = progress.value as? String
        XCTAssertNotNil(oldValue, "\(language): onboarding must expose its progress")
        assertReachable(button, in: app, context: "\(language) onboarding advance")
        XCTAssertTrue(button.isEnabled, language)
        button.tap()
        waitUntil("\(language): onboarding advances exactly to its next screen") {
            progress.exists && (progress.value as? String) != oldValue
        }
    }

    @MainActor
    private func captureStep(_ app: XCUIApplication, sourceTitle: String, language: String, name: String) {
        let title = app.staticTexts["onboarding.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5), "\(language) \(name)")
        assertTranslated(title.label, source: sourceTitle, language: language)
        assertReachable(app.buttons["onboarding.continue"], in: app, context: "\(language) \(name)")
        capture(app, "\(language)-flow-\(name)")
    }

    @MainActor
    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    @MainActor
    private func textField(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        let direct = app.textFields[identifier]
        if direct.waitForExistence(timeout: 2) { return direct }
        // Supports an identifier on the SunkField wrapper without relying on
        // the translated placeholder or on text-field ordering.
        return element(identifier, in: app).descendants(matching: .textField).firstMatch
    }

    @MainActor
    private func assertReachable(_ element: XCUIElement, in app: XCUIApplication, context: String) {
        XCTAssertTrue(element.waitForExistence(timeout: 8), context)
        waitUntil("\(context): control is hittable", timeout: 5) { element.isHittable }
        XCTAssertGreaterThan(element.frame.width, 0, context)
        XCTAssertGreaterThan(element.frame.height, 0, context)
        XCTAssertGreaterThanOrEqual(element.frame.minX, app.frame.minX - 1, context)
        XCTAssertLessThanOrEqual(element.frame.maxX, app.frame.maxX + 1, context)
        XCTAssertGreaterThanOrEqual(element.frame.minY, app.frame.minY - 1, context)
        XCTAssertLessThanOrEqual(element.frame.maxY, app.frame.maxY + 1, context)
    }

    @MainActor
    private func assertTranslated(_ label: String, source: String, language: String) {
        XCTAssertFalse(label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, language)
        if language == "en" {
            XCTAssertEqual(label, source)
        } else {
            XCTAssertNotEqual(label, source, "\(language): untranslated UI text")
        }
    }

    @MainActor
    private func waitUntil(_ message: String, timeout: TimeInterval = 5, condition: @escaping () -> Bool) {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in condition() }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: timeout), .completed, message)
    }

    @MainActor
    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
