import XCTest

final class AboutFlowTests: UITestBase {
    func testOpenAndCloseAboutDeveloper() {
        launchApp()

        openAbout()
        waitFor(app.navigationBars["About Developer"])

        let doneButton = app.buttons["about.backButton"]
        waitFor(doneButton)
        doneButton.tap()
        waitFor(app.buttons["content.menuButton"])
    }
}
