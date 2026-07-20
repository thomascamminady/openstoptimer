import XCTest

final class SimpleStopwatchTests: UITestCase {
    func testStartPauseResume() {
        openMode(cardIdentifier: "home.card.simpleStopwatch", expectedTitle: "Simple Stopwatch")

        let display = element("simpleStopwatch.display")
        XCTAssertTrue(display.waitForExistence(timeout: 3))
        XCTAssertEqual(display.value as? String, "00:00.0")

        app.buttons["playerControls.primary"].tap()
        Thread.sleep(forTimeInterval: 1.2)
        XCTAssertNotEqual(display.value as? String, "00:00.0", "Stopwatch should be counting up")

        app.buttons["playerControls.primary"].tap() // pause
        let frozenValue = display.value as? String
        Thread.sleep(forTimeInterval: 1.0)
        XCTAssertEqual(display.value as? String, frozenValue, "Paused stopwatch must not keep counting")

        // There's no reset button — leaving and reopening the screen is how
        // you get back to a fresh stopwatch.
        XCTAssertFalse(app.buttons["playerControls.reset"].exists)
    }
}
