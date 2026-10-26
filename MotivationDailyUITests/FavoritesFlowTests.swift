import XCTest

final class FavoritesFlowTests: UITestBase {
    func testFavoritesEmptyStateAndSaveFlow() {
        launchApp(additionalArguments: ["-UITestClearFavorites"])

        openFavorites()
        waitFor(app.staticTexts["No Favorites Yet"])

        app.buttons["favorites.doneButton"].tap()

        let saveButton = firstHittable(in: app.buttons.matching(identifier: "content.saveButton"), timeout: 15)
        waitFor(saveButton, timeout: 15)
        waitForHittable(saveButton, timeout: 15)
        saveButton.tap()

        openFavorites()
        waitFor(app.scrollViews["favorites.list"].firstMatch, timeout: 15)
        waitFor(app.otherElements["favorites.cell"].firstMatch, timeout: 15)

        let removeButton = app.buttons["favorites.removeButton"]
        waitFor(removeButton)
        removeButton.tap()

        waitFor(app.staticTexts["No Favorites Yet"])
        app.buttons["favorites.doneButton"].tap()
    }

    func testFullScreenFavoriteAndShare() {
        launchApp()

        openFavorites()
        let cell = app.otherElements["favorites.cell"].firstMatch
        if !cell.waitForExistence(timeout: 5) {
            app.buttons["favorites.doneButton"].tap()
            let saveButton = firstHittable(in: app.buttons.matching(identifier: "content.saveButton"), timeout: 15)
            waitFor(saveButton, timeout: 15)
            waitForHittable(saveButton, timeout: 15)
            saveButton.tap()
            openFavorites()
        }
        waitFor(cell, timeout: 15)
        cell.tap()

        let closeButton = app.buttons["favorites.fullScreen.closeButton"]
        waitFor(closeButton)

        let ratioButton = app.buttons["favorites.fullScreen.ratioButton"]
        waitFor(ratioButton, timeout: 15)
        ratioButton.tap()
        let oneToOne = app.buttons["1:1"]
        if waitFor(oneToOne) {
            oneToOne.tap()
        }

        let shareButton = app.buttons["favorites.fullScreen.shareButton"]
        waitFor(shareButton)
        shareButton.tap()
        waitFor(app.otherElements["share.sheet"])
        app.buttons["share.doneButton"].tap()

        closeButton.tap()
        app.buttons["favorites.doneButton"].tap()
    }

    func testFavoriteImageRetentionAndResizingAcrossRatios() {
        launchApp(additionalArguments: ["-UITestClearFavorites"])

        // Switch to 1:1 on Home
        let ratioButton = firstHittable(in: app.buttons.matching(identifier: "content.ratioButton"), timeout: 15)
        waitFor(ratioButton, timeout: 15)
        waitForHittable(ratioButton, timeout: 15)
        ratioButton.tap()
        let oneToOne = app.buttons["1:1"]
        if waitFor(oneToOne) {
            oneToOne.tap()
        }

        // Save favorite while in 1:1 ratio
        let saveButton = firstHittable(in: app.buttons.matching(identifier: "content.saveButton"), timeout: 15)
        waitFor(saveButton, timeout: 15)
        waitForHittable(saveButton, timeout: 15)
        saveButton.tap()

        // Open Favorites and inspect full screen
        openFavorites()
        let cell = app.otherElements["favorites.cell"].firstMatch
        waitFor(cell, timeout: 15)
        cell.tap()

        let fsCloseButton = app.buttons["favorites.fullScreen.closeButton"]
        waitFor(fsCloseButton, timeout: 15)

        let fsRatioButton = app.buttons["favorites.fullScreen.ratioButton"]
        waitFor(fsRatioButton, timeout: 15)

        // Toggle from 1:1 to Fullscreen
        fsRatioButton.tap()
        let fullscreenOption = app.buttons["Fullscreen"]
        if waitFor(fullscreenOption) {
            fullscreenOption.tap()
        }

        // Toggle to 16:9
        waitForHittable(fsRatioButton, timeout: 10)
        fsRatioButton.tap()
        let sixteenToNineOption = app.buttons["16:9"]
        if waitFor(sixteenToNineOption) {
            sixteenToNineOption.tap()
        }

        // Verify image placeholder not showing "Image not available"
        XCTAssertFalse(app.staticTexts["Image not available"].exists, "Original master image must be retained when resizing")

        fsCloseButton.tap()
        app.buttons["favorites.doneButton"].tap()
    }

    func testFavoritePersistsAcrossAppReopens() {
        // Launch 1: save a favorite
        launchApp(additionalArguments: ["-UITestClearFavorites"])
        let saveButton = firstHittable(in: app.buttons.matching(identifier: "content.saveButton"), timeout: 15)
        waitFor(saveButton, timeout: 15)
        waitForHittable(saveButton, timeout: 15)
        saveButton.tap()

        openFavorites()
        let cell1 = app.otherElements["favorites.cell"].firstMatch
        waitFor(cell1, timeout: 15)
        app.buttons["favorites.doneButton"].tap()

        app.terminate()

        // Launch 2: reopen app (simulating relaunch with potential container UUID shift)
        let reopenedApp = XCUIApplication()
        reopenedApp.launchArguments = ["-UITestMode"]
        reopenedApp.launch()

        let menuButton = reopenedApp.buttons["content.menuButton"]
        waitFor(menuButton, timeout: 15)
        menuButton.tap()

        let favButton = reopenedApp.buttons["Favourites"]
        waitFor(favButton, timeout: 15)
        favButton.tap()

        let cell2 = reopenedApp.otherElements["favorites.cell"].firstMatch
        XCTAssertTrue(cell2.waitForExistence(timeout: 15), "Saved favorite must persist across reopens")

        reopenedApp.buttons["favorites.doneButton"].tap()
    }
}
