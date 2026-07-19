import XCTest

final class LapStopwatchTests: UITestCase {
    func testRecordingLapsAddsRowsAndResetClearsThem() {
        openMode(cardIdentifier: "home.card.lapStopwatch", expectedTitle: "Lap Stopwatch")

        app.buttons["playerControls.primary"].tap() // start

        app.buttons["lapStopwatch.lap"].tap()
        Thread.sleep(forTimeInterval: 0.6)
        app.buttons["lapStopwatch.lap"].tap()
        Thread.sleep(forTimeInterval: 0.6)
        app.buttons["lapStopwatch.lap"].tap()

        XCTAssertTrue(element("lapStopwatch.lapRow.1").waitForExistence(timeout: 3))
        XCTAssertTrue(element("lapStopwatch.lapRow.2").exists)
        XCTAssertTrue(element("lapStopwatch.lapRow.3").exists)

        app.buttons["playerControls.primary"].tap() // pause, so the reset control is available
        app.buttons["lapStopwatch.reset"].tap()

        XCTAssertFalse(element("lapStopwatch.lapRow.1").exists)
        XCTAssertEqual(element("lapStopwatch.display").value as? String, "00:00.0")
    }
}
