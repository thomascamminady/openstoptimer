import XCTest

final class SettingsTests: UITestCase {
    private func openSettings() {
        XCTAssertTrue(app.navigationBars["OpenStopTimer"].waitForExistence(timeout: 5))
        app.buttons["home.settingsButton"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
    }

    private func waitForSwitchValue(_ element: XCUIElement, toEqual expected: String, timeout: TimeInterval = 5) {
        let predicate = NSPredicate(format: "value == %@", expected)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        XCTAssertEqual(
            XCTWaiter().wait(for: [expectation], timeout: timeout), .completed,
            "switch never became '\(expected)' (last: '\(element.value ?? "nil")')"
        )
    }

    func testTogglingSoundsHidesAndShowsSoundPickers() {
        openSettings()

        let soundsToggle = app.switches["settings.soundsEnabledToggle"]
        XCTAssertTrue(soundsToggle.waitForExistence(timeout: 3))
        XCTAssertEqual(soundsToggle.value as? String, "1", "Sounds should be enabled by default")

        // A sound-event picker row should be visible while sounds are enabled.
        XCTAssertTrue(app.staticTexts["Phase Start"].waitForExistence(timeout: 3))

        tapSwitch(soundsToggle)
        waitForSwitchValue(soundsToggle, toEqual: "0")
        XCTAssertFalse(app.staticTexts["Phase Start"].exists, "Sound pickers should hide once sounds are disabled")

        tapSwitch(soundsToggle)
        waitForSwitchValue(soundsToggle, toEqual: "1")
        XCTAssertTrue(app.staticTexts["Phase Start"].waitForExistence(timeout: 3))
    }

    func testResetToDefaultsRestoresSoundsEnabled() {
        openSettings()
        let soundsToggle = app.switches["settings.soundsEnabledToggle"]
        XCTAssertTrue(soundsToggle.waitForExistence(timeout: 3))

        tapSwitch(soundsToggle)
        waitForSwitchValue(soundsToggle, toEqual: "0")

        let resetButton = app.buttons["settings.resetButton"]
        scrollDownUntilVisible(resetButton)
        XCTAssertTrue(resetButton.exists, "Reset button should be reachable by scrolling down")
        resetButton.tap()
        waitForSwitchValue(soundsToggle, toEqual: "1", timeout: 5)
    }
}
