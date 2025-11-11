import XCTest

final class ShareDialogTests: UITestBase {
    func testSaveToPhotosDialog() {
        launchApp()

        let shareButton = firstHittable(in: app.buttons.matching(identifier: "content.shareButton"), timeout: 15)
        waitFor(shareButton, timeout: 15)
        waitForHittable(shareButton, timeout: 15)
        shareButton.tap()
        waitForShareSheet(timeout: 15)

        let saveButton = app.buttons["share.saveToPhotosButton"]
        waitFor(saveButton)
        saveButton.tap()

        let dialogTitle = "Save to Photos"
        let dialog = app.sheets[dialogTitle].exists ? app.sheets[dialogTitle] : app.alerts[dialogTitle]
        waitFor(dialog)

        if dialog.buttons["Cancel"].exists {
            dialog.buttons["Cancel"].tap()
        }

        app.buttons["share.doneButton"].tap()
    }
}
