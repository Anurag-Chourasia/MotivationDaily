import XCTest

final class HomeFlowTests: UITestBase {
    func testHomeControlsAndShareSheet() {
        launchApp()

        waitFor(app.buttons["content.menuButton"], timeout: 15)
        waitFor(app.scrollViews["content.categoryTabs"].firstMatch, timeout: 15)

        let shareButton = firstHittable(in: app.buttons.matching(identifier: "content.shareButton"), timeout: 15)
        waitFor(shareButton, timeout: 15)
        waitForHittable(shareButton, timeout: 15)
        shareButton.tap()

        waitForShareSheet(timeout: 15)

        let copyButton = app.buttons["share.copyQuoteButton"]
        waitFor(copyButton)
        copyButton.tap()

        let copiedAlert = app.alerts["Copied!"]
        waitFor(copiedAlert)
        copiedAlert.buttons["OK"].tap()

        let doneButton = app.buttons["share.doneButton"]
        waitFor(doneButton)
        doneButton.tap()
    }

    func testChangeAspectRatioMenu() {
        launchApp()

        let ratioButton = firstHittable(in: app.buttons.matching(identifier: "content.ratioButton"), timeout: 15)
        waitFor(ratioButton, timeout: 15)
        waitForHittable(ratioButton, timeout: 15)
        ratioButton.tap()

        let oneToOne = app.buttons["1:1"]
        if waitFor(oneToOne) {
            oneToOne.tap()
        }

        // Switch to 16:9
        waitForHittable(ratioButton, timeout: 10)
        ratioButton.tap()
        let sixteenToNine = app.buttons["16:9"]
        if waitFor(sixteenToNine) {
            sixteenToNine.tap()
        }

        // Switch to 9:16
        waitForHittable(ratioButton, timeout: 10)
        ratioButton.tap()
        let nineToSixteen = app.buttons["9:16"]
        if waitFor(nineToSixteen) {
            nineToSixteen.tap()
        }

        // Switch back to Fullscreen
        waitForHittable(ratioButton, timeout: 10)
        ratioButton.tap()
        let fullscreen = app.buttons["Fullscreen"]
        if waitFor(fullscreen) {
            fullscreen.tap()
        }

        // Verify ratio button is still hittable and app is responsive
        waitForHittable(ratioButton, timeout: 10)
    }

    func testCategorySwitching() {
        launchApp()

        waitFor(app.buttons["content.menuButton"], timeout: 15)
        let categoryTabs = app.scrollViews["content.categoryTabs"].firstMatch
        waitFor(categoryTabs, timeout: 15)

        let buttons = categoryTabs.buttons.allElementsBoundByIndex
        XCTAssertGreaterThan(buttons.count, 1, "Expected multiple category tabs")

        for button in buttons.prefix(3) {
            if button.isHittable {
                button.tap()
                RunLoop.current.run(until: Date().addingTimeInterval(1.0))
            }
        }
    }

    func testRealCategoryTabsLoading() {
        let realApp = XCUIApplication()
        realApp.launch()

        waitFor(realApp.buttons["content.menuButton"], timeout: 15)
        let categoryTabs = realApp.scrollViews["content.categoryTabs"].firstMatch
        waitFor(categoryTabs, timeout: 15)

        let happinessTab = categoryTabs.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Happiness'")).firstMatch
        XCTAssertTrue(happinessTab.waitForExistence(timeout: 10), "Happiness tab should exist")
        happinessTab.tap()

        // Give it a moment to load and verify no alert appears
        RunLoop.current.run(until: Date().addingTimeInterval(3.0))
        XCTAssertFalse(realApp.alerts["Refresh Failed"].exists, "No Refresh Failed alert should appear")
        XCTAssertFalse(realApp.alerts["End of this section"].exists, "No End of this section alert should appear")
    }

    func testRandomizationAcrossLaunches() {
        var observedQuotes: Set<String> = []

        for _ in 0..<3 {
            let instance = XCUIApplication()
            instance.launch()

            let quoteLabel = instance.staticTexts.matching(NSPredicate(format: "label BEGINSWITH '\"'")).firstMatch
            XCTAssertTrue(quoteLabel.waitForExistence(timeout: 15), "Quote text should exist on launch")
            observedQuotes.insert(quoteLabel.label)

            instance.terminate()
        }

        XCTAssertGreaterThan(observedQuotes.count, 1, "App should randomize quotes across launches")
    }
}
