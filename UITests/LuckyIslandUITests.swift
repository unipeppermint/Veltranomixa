import XCTest

final class LuckyIslandUITests: XCTestCase {
    func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
    func tap(_ app: XCUIApplication, _ name: String) {
        let button = app.buttons[name]
        for _ in 0..<5 where !button.isHittable { app.swipeUp() }
        XCTAssertTrue(button.waitForExistence(timeout: 5), name); button.tap()
    }
    func testCompleteRunAndRecovery() {
        let app = XCUIApplication(); app.launchEnvironment["ISLAND_UI_TEST_SESSION"] = "1"; app.launchEnvironment["ISLAND_UI_FIXED_WOOD"] = "1"; app.launch()
        if app.buttons["Let's begin"].waitForExistence(timeout: 3) { app.buttons["Let's begin"].tap() }
        tap(app,"tab.Settings"); tap(app,"Reset all progress"); app.alerts.buttons["Reset progress"].tap()
        capture("01-island")
        tap(app,"Start challenge"); app.alerts.buttons["Start challenge"].tap()
        capture("02-game")
        tap(app, "game.workshop")
        let preview = app.staticTexts["workshop.preview"]
        XCTAssertTrue(preview.label.contains("37.5% → 50.0%"))
        tap(app, "workshop.slot.3")
        XCTAssertTrue(app.staticTexts["workshop.preview"].label.contains("Breeze → Wood"))
        tap(app, "workshop.slot.1")
        tap(app, "workshop.apply")
        XCTAssertTrue(app.staticTexts["game.message"].label.contains("50.0%"))
        capture("10-refitted-wheel")
        tap(app, "game.workshop")
        let apply = app.buttons["workshop.apply"]
        XCTAssertEqual(apply.label, "Confirm swap · 6 coins")
        XCTAssertFalse(apply.isEnabled)
        tap(app, "Back to game")
        tap(app,"game.spin")
        app.terminate(); app.launch()
        if app.buttons["Let's begin"].waitForExistence(timeout: 2) { app.buttons["Let's begin"].tap() }
        let resume = app.buttons.matching(NSPredicate(format:"label CONTAINS %@", "Continue ·")).firstMatch
        XCTAssertTrue(resume.waitForExistence(timeout: 5)); resume.tap()
        capture("03-recovered")
        var ended = false
        for _ in 0..<100 {
            if app.buttons["Confirm upgrade"].exists {
                capture("04-upgrade"); tap(app,"Confirm upgrade")
            } else if app.buttons["Try again"].exists { ended = true; break }
            else { tap(app,"game.spin"); _ = app.buttons["Confirm upgrade"].waitForExistence(timeout: 4) }
        }
        XCTAssertTrue(ended); XCTAssertTrue(app.buttons["Next stop"].exists); capture("05-result"); tap(app,"Back to island")
        tap(app,"tab.Collection"); capture("06-collection")
        tap(app,"tab.Settings"); capture("07-settings")
        XCTAssertTrue(app.switches["Sound effects"].exists)
    }
    func testWheelHalfTurnAndRecovery() {
        let app = XCUIApplication()
        app.launchEnvironment["ISLAND_UI_TEST_SESSION"] = "1"
        app.launchEnvironment["ISLAND_UI_FIXED_WOOD"] = "1"
        app.launchEnvironment["ISLAND_UI_FIXED_INDEX"] = "4"
        app.launch()
        if app.buttons["Let's begin"].waitForExistence(timeout: 2) { app.buttons["Let's begin"].tap() }
        tap(app, "tab.Settings"); tap(app, "Reset all progress"); app.alerts.buttons["Reset progress"].tap()
        // Reset clears the onboarding flag. Finish it explicitly before testing recovery.
        tap(app, "tab.Settings"); tap(app, "How to play")
        app.alerts.buttons["Let's begin"].tap(); tap(app, "tab.Island")
        tap(app, "Start challenge"); app.alerts.buttons["Start challenge"].tap()
        tap(app, "game.spin")
        let awarded = NSPredicate(format: "label == %@", "Wood +1")
        expectation(for: awarded, evaluatedWith: app.staticTexts["game.message"])
        waitForExpectations(timeout: 8)
        capture("13-wheel-half-turn-upright")
        app.terminate(); app.launch()
        let resume = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Continue ·")).firstMatch
        XCTAssertTrue(resume.waitForExistence(timeout: 5)); resume.tap()
        XCTAssertTrue(app.buttons["game.spin"].waitForExistence(timeout: 5))
        capture("14-wheel-recovered-upright")
    }
    func testLargeTextWorkshopPreview() {
        let app = XCUIApplication()
        app.launchEnvironment["ISLAND_UI_TEST_SESSION"] = "1"
        app.launchArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        if app.buttons["Let's begin"].waitForExistence(timeout: 2) { app.buttons["Let's begin"].tap() }
        tap(app, "tab.Settings"); tap(app, "Reset all progress"); app.alerts.buttons["Reset progress"].tap()
        tap(app, "Start challenge"); app.alerts.buttons["Start challenge"].tap()
        tap(app, "game.workshop")
        capture("11-workshop-large-text-layout")
        let apply = app.buttons["workshop.apply"]
        for _ in 0..<8 where !apply.isHittable { app.swipeUp() }
        XCTAssertTrue(apply.isHittable)
        XCTAssertTrue(app.staticTexts["workshop.preview"].label.contains("37.5% → 50.0%"))
        capture("12-workshop-large-text-preview")
        apply.tap()
        XCTAssertTrue(app.staticTexts["game.message"].label.contains("50.0%"))
    }
    func testLargeTextSettingsAndCollection() {
        let app = XCUIApplication()
        app.launchEnvironment["ISLAND_UI_TEST_SESSION"] = "1"
        app.launchArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        if app.buttons["Let's begin"].waitForExistence(timeout: 2) { app.buttons["Let's begin"].tap() }
        tap(app, "tab.Collection"); capture("08-large-text-collection")
        tap(app, "tab.Settings"); capture("09-large-text-settings")
        XCTAssertTrue(app.switches["Sound effects"].exists)
        app.switches["Sound effects"].tap()
        let value = app.switches["Sound effects"].value as? String
        app.terminate(); app.launch(); tap(app,"tab.Settings")
        XCTAssertEqual(app.switches["Sound effects"].value as? String, value)
    }

}


extension LuckyIslandUITests {
    func testPrivacyAndWheelAccessibility() {
        let app = XCUIApplication()
        app.launchEnvironment["ISLAND_UI_TEST_SESSION"] = "1"
        app.launchArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        if app.buttons["Let's begin"].waitForExistence(timeout: 2) { app.buttons["Let's begin"].tap() }
        tap(app, "tab.Settings"); tap(app, "Save Information")
        let policy = app.alerts["Save Information"]
        XCTAssertTrue(policy.waitForExistence(timeout: 3))
        let text = policy.staticTexts.allElementsBoundByIndex.map(\.label).joined(separator: " ")
        XCTAssertTrue(text.contains("iCloud Backup or a computer backup"))
        XCTAssertTrue(text.contains("It does not delete existing device backups"))
        XCTAssertTrue(policy.buttons["Got it"].isHittable)
        capture("15-save-information-large-text")
        policy.buttons["Got it"].tap()
        tap(app, "Reset all progress"); app.alerts.buttons["Reset progress"].tap()
        tap(app, "Start challenge"); app.alerts.buttons["Start challenge"].tap()
        let wheel = app.otherElements["game.wheel"]
        XCTAssertTrue(wheel.waitForExistence(timeout: 3))
        XCTAssertTrue(wheel.label.contains("Choose one of three upgrades"))
        XCTAssertTrue(wheel.label.contains("Prepare Breeze to double the next Wood or Coins reward"))
        XCTAssertFalse(wheel.label.contains("next-spin yield 0"))
    }
}
