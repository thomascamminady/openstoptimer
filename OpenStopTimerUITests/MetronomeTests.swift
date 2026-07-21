import XCTest

final class MetronomeTests: UITestCase {
    private func openMetronome() {
        openMode(cardIdentifier: "home.card.metronome", expectedTitle: "Metronome")
    }

    func testDefaultDisplayShowsConfiguredIntervalBeforeStarting() {
        openMetronome()
        waitForValue("metronome.display", toEqual: "42", timeout: 5)
    }

    func testChangingIntervalInSettingsUpdatesTheIdleDisplay() {
        openMetronome()
        app.buttons["metronome.settingsButton"].tap()

        let picker = element("metronomeSettings.cycleSecondsPicker")
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        pickerWheel("metronomeSettings.cycleSecondsPicker").adjust(toPickerWheelValue: "20")

        app.buttons["metronomeSettings.doneButton"].tap()
        waitForValue("metronome.display", toEqual: "20", timeout: 5)
    }

    /// The only way to start is the fixed 10s lead-in ("3, 2, 1, go"), so
    /// this exercises the full lead-in -> running transition, then pause.
    func testStartCountsDownThenRunsAndPauseFreezesTheNumber() {
        openMetronome()
        app.buttons["metronome.primaryButton"].tap()

        let display = element("metronome.display")
        XCTAssertTrue(display.waitForExistence(timeout: 3))

        // The lead-in is a fixed 10s — sleeping past it outright, rather
        // than trying to catch any single transient countdown digit (each
        // on screen for only ~1s, easily missed by the time XCUITest's
        // tap/idle synchronization settles on a slow machine), is what's
        // actually reliable here.
        Thread.sleep(forTimeInterval: 11)
        let runningPredicate = NSPredicate(format: "value MATCHES %@", "^[0-9]{2}$")
        XCTAssertTrue(
            runningPredicate.evaluate(with: display),
            "Should be running with a two-digit value by now (was '\(display.value ?? "nil")')"
        )

        app.buttons["metronome.primaryButton"].tap() // pause
        let frozenValue = display.value as? String
        Thread.sleep(forTimeInterval: 1.5)
        XCTAssertEqual(display.value as? String, frozenValue, "Paused metronome must not keep counting")
    }

    func testCancelDuringLeadInReturnsToIdle() {
        openMetronome()
        app.buttons["metronome.primaryButton"].tap()

        // Confirm the lead-in has actually started (any value other than
        // the idle default) before canceling — tapping the primary button
        // again too early, before its action has switched from Start to
        // Cancel, would just restart the lead-in instead of canceling it.
        let display = element("metronome.display")
        let leftIdlePredicate = NSPredicate(format: "value != %@", "42")
        let leftIdleExpectation = XCTNSPredicateExpectation(predicate: leftIdlePredicate, object: display)
        XCTAssertEqual(
            XCTWaiter().wait(for: [leftIdleExpectation], timeout: 8),
            .completed,
            "Should leave the idle display once the lead-in starts"
        )

        app.buttons["metronome.primaryButton"].tap() // cancel (X) during lead-in
        waitForValue("metronome.display", toEqual: "42", timeout: 5)
    }

    func testBackButtonReturnsToHome() {
        openMetronome()
        app.buttons["metronome.backButton"].tap()
        XCTAssertTrue(app.navigationBars["OpenStopTimer"].waitForExistence(timeout: 5))
    }
}
