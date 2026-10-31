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
    func testSaveAllImageFormatsToSimulatorPhotos() {
        launchApp()
        let share = firstHittable(in: app.buttons.matching(identifier: "content.shareButton"), timeout: 15)
        waitForHittable(share)
        share.tap()
        waitForShareSheet()

        for option in ["Save Quote (Black Gradient)", "Save Only Image", "Save Image + Quote"] {
            let save = app.buttons["share.saveToPhotosButton"]
            waitForEnabled(save)
            if !save.isHittable { app.swipeUp() }
            waitForHittable(save)
            save.tap()
            let choice = app.buttons[option]
            waitFor(choice)
            choice.tap()

            let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
            let permission = springboard.alerts.firstMatch
            if permission.waitForExistence(timeout: 2) {
                let allow = permission.buttons.matching(NSPredicate(format: "label BEGINSWITH[c] 'Allow'")).firstMatch
                XCTAssertTrue(allow.exists, "Expected add-only Photos authorization")
                allow.tap()
            }
            let success = app.alerts["Saved"]
            waitFor(success, timeout: 15)
            XCTAssertTrue(success.staticTexts["Image saved to Photos."].exists)
            success.buttons["OK"].tap()
        }
    }

}
