import XCTest

class UITestBase: XCTestCase {
    private(set) var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
    }

    func launchApp(additionalArguments: [String] = []) {
        app.launchArguments = ["-UITestMode"] + additionalArguments
        app.launch()
    }

    @discardableResult
    func waitFor(_ element: XCUIElement, timeout: TimeInterval = 6, file: StaticString = #filePath, line: UInt = #line) -> Bool {
        let exists = element.waitForExistence(timeout: timeout)
        if !exists {
            XCTFail("Expected element to exist: \(element)", file: file, line: line)
        }
        return exists
    }

    func waitForEnabled(_ element: XCUIElement, timeout: TimeInterval = 6, file: StaticString = #filePath, line: UInt = #line) {
        let predicate = NSPredicate(format: "isEnabled == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        if result != .completed {
            XCTFail("Expected element to become enabled: \(element)", file: file, line: line)
        }
    }

    func waitForHittable(_ element: XCUIElement, timeout: TimeInterval = 10, file: StaticString = #filePath, line: UInt = #line) {
        let predicate = NSPredicate(format: "isHittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        if result != .completed {
            XCTFail("Expected element to become hittable: \(element)", file: file, line: line)
        }
    }

    func firstHittable(in query: XCUIElementQuery, timeout: TimeInterval = 10) -> XCUIElement {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let elements = query.allElementsBoundByIndex
            if let element = elements.first(where: { $0.isHittable }) {
                return element
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        return query.firstMatch
    }

    func openMenu() {
        let menuButton = app.buttons["content.menuButton"]
        waitFor(menuButton)
        menuButton.tap()
    }

    func openFavorites() {
        openMenu()
        let favoritesButton = app.buttons["Favourites"]
        waitFor(favoritesButton)
        favoritesButton.tap()
        waitFor(app.buttons["favorites.doneButton"], timeout: 10)
    }

    func openAbout() {
        openMenu()
        let aboutButton = app.buttons["About Developer"]
        waitFor(aboutButton)
        aboutButton.tap()
    }

    func waitForShareSheet(timeout: TimeInterval = 10) {
        let doneButton = app.buttons["share.doneButton"].firstMatch
        if doneButton.waitForExistence(timeout: timeout) {
            return
        }
        let sheet = app.otherElements["share.sheet"].firstMatch
        waitFor(sheet, timeout: timeout)
    }
}
