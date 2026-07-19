import XCTest

final class HomeNavigationTests: UITestCase {
    func testAllFourModesAndSettingsAreReachableFromHome() {
        XCTAssertTrue(app.navigationBars["OpenStopTimer"].waitForExistence(timeout: 5))

        openMode(cardIdentifier: "home.card.simpleTimer", expectedTitle: "Simple Timer")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        openMode(cardIdentifier: "home.card.simpleStopwatch", expectedTitle: "Simple Stopwatch")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        openMode(cardIdentifier: "home.card.lapStopwatch", expectedTitle: "Lap Stopwatch")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        openMode(cardIdentifier: "home.card.hiit", expectedTitle: "HIIT Workouts")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        XCTAssertTrue(app.navigationBars["OpenStopTimer"].waitForExistence(timeout: 5))
        app.buttons["home.settingsButton"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
    }
}
