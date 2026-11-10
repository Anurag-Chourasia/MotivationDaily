import XCTest

final class AboutFlowTests: UITestBase {
    func testOpenAndCloseAboutDeveloper() {
        launchApp()

        openAbout()
        waitFor(app.navigationBars["About Developer"])

        let screenshot = app.screenshot()
        try? screenshot.pngRepresentation.write(to: URL(fileURLWithPath: "/tmp/about_developer_modal.png"))

        let doneButton = app.buttons["about.backButton"]
        waitFor(doneButton)
        doneButton.tap()
        waitFor(app.buttons["content.menuButton"])
    }
}
