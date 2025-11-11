import XCTest

final class AboutFlowTests: UITestBase {
    func testOpenAndCloseAboutDeveloper() {
        launchApp()

        openAbout()
        waitFor(app.navigationBars["About Developer"])

        let doneButton = app.navigationBars.buttons["Done"]
        waitFor(doneButton)
        doneButton.tap()
    }
}
