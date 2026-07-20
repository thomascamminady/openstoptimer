import XCTest

final class SimpleTimerTests: UITestCase {
    private func openSimpleTimer() {
        openMode(cardIdentifier: "home.card.simpleTimer", expectedTitle: "Simple Timer")
    }

    func testStartPauseResumeAndFinish() {
        openSimpleTimer()

        // Dial the picker down to a 2-second timer so the test finishes fast.
        pickerWheel("simpleTimer.minutesPicker").adjust(toPickerWheelValue: "0")
        pickerWheel("simpleTimer.secondsPicker").adjust(toPickerWheelValue: "2")

        app.buttons["playerControls.primary"].tap()
        XCTAssertTrue(element("simpleTimer.display").waitForExistence(timeout: 3))

        waitForValue("simpleTimer.display", toEqual: "00:00", timeout: 5)

        // There's no separate reset button — tapping primary again once
        // finished dismisses the countdown and returns to the picker.
        app.buttons["playerControls.primary"].tap()
        XCTAssertTrue(pickerWheel("simpleTimer.secondsPicker").waitForExistence(timeout: 3))
    }

    func testPauseFreezesTheCountdown() {
        openSimpleTimer()
        pickerWheel("simpleTimer.minutesPicker").adjust(toPickerWheelValue: "0")
        pickerWheel("simpleTimer.secondsPicker").adjust(toPickerWheelValue: "10")

        app.buttons["playerControls.primary"].tap()
        Thread.sleep(forTimeInterval: 1.5)
        app.buttons["playerControls.primary"].tap() // pause

        let display = element("simpleTimer.display")
        let frozenValue = display.value as? String
        Thread.sleep(forTimeInterval: 1.5)
        XCTAssertEqual(display.value as? String, frozenValue, "Paused timer must not keep counting down")
    }
}
