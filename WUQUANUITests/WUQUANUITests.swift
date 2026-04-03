//
//  WUQUANUITests.swift
//  WUQUANUITests
//
//  Created by shuming li on 7/19/25.
//

import XCTest

final class WUQUANUITests: XCTestCase {

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
    func testCharacterSelectionToGameStart() throws {
        let app = XCUIApplication()
        app.launch()

        // Handle media permission dialog if it appears
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allowBtn = springboard.buttons["Don't Allow"]
        if allowBtn.waitForExistence(timeout: 3) {
            allowBtn.tap()
        }

        // Verify character selection screen appears
        let title = app.staticTexts["选择你的角色"]
        XCTAssertTrue(title.waitForExistence(timeout: 5), "Character selection screen should appear")

        // Tap first character cell (player)
        let firstCell = app.collectionViews.cells.element(boundBy: 0)
        XCTAssertTrue(firstCell.waitForExistence(timeout: 3))
        firstCell.tap()

        // Verify prompt changed to opponent selection
        let opponentTitle = app.staticTexts["选择你的对手"]
        XCTAssertTrue(opponentTitle.waitForExistence(timeout: 3), "Should show opponent selection prompt")

        // Tap second character cell (opponent — different from player)
        let secondCell = app.collectionViews.cells.element(boundBy: 1)
        secondCell.tap()

        // Verify start button appears
        let startButton = app.buttons["开始游戏！"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 3), "Start button should appear")

        // Tap start
        startButton.tap()

        // Verify game started — the SKView should be showing game content
        // The character selection should be dismissed
        XCTAssertFalse(opponentTitle.waitForExistence(timeout: 3), "Selection screen should be dismissed")
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
