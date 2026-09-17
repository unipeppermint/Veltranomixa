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
        let app = XCUIApplication(); app.launchEnvironment["ISLAND_UI_FIXED_WOOD"] = "1"; app.launch()
        if app.buttons["让好运靠岸"].waitForExistence(timeout: 3) { app.buttons["让好运靠岸"].tap() }
        tap(app,"tab.设置"); tap(app,"清空所有进度"); app.alerts.buttons["清空进度"].tap()
        capture("01-island")
        tap(app,"开始挑战"); app.alerts.buttons["开始挑战"].tap()
        capture("02-game")
        tap(app,"game.spin")
        app.terminate(); app.launch()
        if app.buttons["让好运靠岸"].waitForExistence(timeout: 2) { app.buttons["让好运靠岸"].tap() }
        let resume = app.buttons.matching(NSPredicate(format:"label CONTAINS %@", "继续 ·")).firstMatch
        XCTAssertTrue(resume.waitForExistence(timeout: 5)); resume.tap()
        capture("03-recovered")
        var ended = false
        for _ in 0..<100 {
            if app.buttons["确认升级"].exists {
                capture("04-upgrade"); tap(app,"确认升级")
            } else if app.buttons["再挑战一次"].exists { ended = true; break }
            else { tap(app,"game.spin"); _ = app.buttons["确认升级"].waitForExistence(timeout: 4) }
        }
        XCTAssertTrue(ended); XCTAssertTrue(app.buttons["下一站"].exists); capture("05-result"); tap(app,"回到小岛")
        tap(app,"tab.收藏"); capture("06-collection")
        tap(app,"tab.设置"); capture("07-settings")
        XCTAssertTrue(app.switches["游戏音效"].exists)
    }
    func testLargeTextSettingsAndCollection() {
        let app = XCUIApplication()
        app.launchArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        if app.buttons["让好运靠岸"].waitForExistence(timeout: 2) { app.buttons["让好运靠岸"].tap() }
        tap(app, "tab.收藏"); capture("08-large-text-collection")
        tap(app, "tab.设置"); capture("09-large-text-settings")
        XCTAssertTrue(app.switches["游戏音效"].exists)
        app.switches["游戏音效"].tap()
        let value = app.switches["游戏音效"].value as? String
        app.terminate(); app.launch(); tap(app,"tab.设置")
        XCTAssertEqual(app.switches["游戏音效"].value as? String, value)
    }

}
