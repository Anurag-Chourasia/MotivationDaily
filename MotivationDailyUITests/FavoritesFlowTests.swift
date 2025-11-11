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
        let nineToSixteen = app.buttons["9:16"]
        if waitFor(nineToSixteen) {
            nineToSixteen.tap()
        }

        let shareButton = app.buttons["favorites.fullScreen.shareButton"]
        waitFor(shareButton)
        shareButton.tap()
        waitFor(app.otherElements["share.sheet"])
        app.buttons["share.doneButton"].tap()

        closeButton.tap()
        app.buttons["favorites.doneButton"].tap()
    }
}
