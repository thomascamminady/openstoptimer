import XCTest

final class SettingsTests: UITestCase {
    private func openSettings() {
        XCTAssertTrue(app.navigationBars["OpenStopTimer"].waitForExistence(timeout: 5))
        app.buttons["home.settingsButton"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
    }

    func testTogglingSoundsHidesAndShowsSoundPickers() {
        openSettings()

        let soundsToggle = app.switches["settings.soundsEnabledToggle"]
        XCTAssertTrue(soundsToggle.waitForExistence(timeout: 3))
        XCTAssertEqual(soundsToggle.value as? String, "1", "Sounds should be enabled by default")

        // A sound-event picker row should be visible while sounds are enabled.
        XCTAssertTrue(app.staticTexts["Phase Start"].waitForExistence(timeout: 3))

        soundsToggle.tap()
        XCTAssertEqual(soundsToggle.value as? String, "0")
        XCTAssertFalse(app.staticTexts["Phase Start"].exists, "Sound pickers should hide once sounds are disabled")

        soundsToggle.tap()
        XCTAssertEqual(soundsToggle.value as? String, "1")
        XCTAssertTrue(app.staticTexts["Phase Start"].waitForExistence(timeout: 3))
    }

    func testResetToDefaultsRestoresSoundsEnabled() {
        openSettings()
        let soundsToggle = app.switches["settings.soundsEnabledToggle"]
        XCTAssertTrue(soundsToggle.waitForExistence(timeout: 3))

        soundsToggle.tap()
        XCTAssertEqual(soundsToggle.value as? String, "0")

        app.buttons["settings.resetButton"].tap()
        XCTAssertEqual(soundsToggle.value as? String, "1", "Reset to Defaults should re-enable sounds")
    }
}
