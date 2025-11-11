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
    }
}
