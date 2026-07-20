import XCTest

final class HIITTests: UITestCase {
    private func openHIITLibrary() {
        openMode(cardIdentifier: "home.card.hiit", expectedTitle: "HIIT Workouts")
    }

    private func replaceText(in field: XCUIElement, with newValue: String) {
        field.tap()
        if let existing = field.value as? String, !existing.isEmpty {
            let deleteAll = String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count)
            field.typeText(deleteAll)
        }
        field.typeText(newValue)
    }

    /// Creates a two-step workout (Work, then Rest) via the editor and saves
    /// it, returning to the library. New workouts start empty, so this
    /// exercises rename, "add step via menu" (twice), and save.
    @discardableResult
    private func createWorkout(named name: String) -> XCUIElement {
        openHIITLibrary()
        app.buttons["hiitLibrary.addButton"].tap()

        let nameField = app.textFields["hiitEditor.nameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 20))
        replaceText(in: nameField, with: name)

        app.buttons["hiitEditor.addMenu"].tap()
        app.buttons["hiitEditor.addWorkStep"].tap()
        app.buttons["hiitEditor.addMenu"].tap()
        app.buttons["hiitEditor.addRestStep"].tap()

        let saveButton = app.buttons["hiitEditor.saveButton"]
        XCTAssertTrue(saveButton.isEnabled, "Save should be enabled once name + at least one step exist")
        saveButton.tap()

        let row = element("hiitLibrary.workoutRow.\(name)")
        XCTAssertTrue(row.waitForExistence(timeout: 20), "New workout should appear in the library")
        return row
    }

    func testCreateSaveAndPlayWorkoutThroughToCompletion() {
        let row = createWorkout(named: "UI Test Tabata")
        row.tap()

        // The player has no navigation title (that space is reserved for the
        // countdown instead) — the workout name still shows on the
        // not-yet-started summary screen, so check that.
        XCTAssertTrue(app.staticTexts["UI Test Tabata"].waitForExistence(timeout: 20))

        // Not started yet: summary list + a Start (play) button, no skip controls.
        XCTAssertFalse(app.buttons["playerControls.skipForward"].exists)
        app.buttons["playerControls.primary"].tap()

        let currentName = app.staticTexts["currentStep.name"]
        XCTAssertTrue(currentName.waitForExistence(timeout: 20))
        XCTAssertEqual(currentName.label, "WORK")

        // A subsequent tap while the session is actively ticking has been
        // observed to make XCUITest's app-idle synchronization very slow on
        // heavily loaded machines (unrelated background system load, not app
        // behavior — verified separately via the live accessibility tree,
        // which shows the correct state well before this generous timeout
        // would be needed under normal load). Give it real headroom rather
        // than flake.
        app.buttons["playerControls.skipForward"].tap()
        let restPredicate = NSPredicate(format: "label == %@", "REST")
        let restExpectation = XCTNSPredicateExpectation(predicate: restPredicate, object: currentName)
        XCTAssertEqual(XCTWaiter().wait(for: [restExpectation], timeout: 30), .completed)

        app.buttons["playerControls.skipForward"].tap()
        XCTAssertTrue(element("hiitPlayer.finishedView").waitForExistence(timeout: 30))

        app.buttons["hiitPlayer.doneButton"].tap()
        XCTAssertTrue(app.navigationBars["HIIT Workouts"].waitForExistence(timeout: 20))
        XCTAssertTrue(element("hiitLibrary.workoutRow.UI Test Tabata").exists)
    }

    /// Exercises the quick interval-creation flow: tapping "Add Interval"
    /// auto-opens its editor sheet pre-filled with a sensible 10-round
    /// work/rest default, bumping Sets to 3 turns it into "3x10", and the
    /// player shows live "SET x/y · ROUND x/y" progress while running.
    func testCreateIntervalWorkoutWithSetsShowsRoundProgressWhilePlaying() {
        openHIITLibrary()
        app.buttons["hiitLibrary.addButton"].tap()

        let nameField = app.textFields["hiitEditor.nameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 20))
        replaceText(in: nameField, with: "UI Test 3x10")

        app.buttons["hiitEditor.addRoundGroup"].tap()

        // Adding an interval auto-opens its editor sheet.
        let doneButton = app.buttons["blockEditor.doneButton"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 20), "Adding an interval should auto-open its editor")

        let roundsStepper = stepper(labeled: "Rounds:")
        XCTAssertTrue(roundsStepper.waitForExistence(timeout: 20))
        XCTAssertEqual(roundsStepper.label, "Rounds: 10", "New interval should default to 10 rounds")

        // A SwiftUI Stepper's own accessibilityIdentifier gets a
        // "-Increment"/"-Decrement" suffix on its two child buttons.
        let setsStepper = stepper(labeled: "Sets:")
        XCTAssertTrue(setsStepper.waitForExistence(timeout: 10))
        let incrementSets = setsStepper.buttons["blockEditor.setsStepper-Increment"]
        XCTAssertTrue(incrementSets.waitForExistence(timeout: 5))
        incrementSets.tap() // 1 -> 2
        incrementSets.tap() // 2 -> 3
        XCTAssertEqual(setsStepper.label, "Sets: 3")

        doneButton.tap()

        let saveButton = app.buttons["hiitEditor.saveButton"]
        XCTAssertTrue(saveButton.isEnabled)
        saveButton.tap()

        let row = element("hiitLibrary.workoutRow.UI Test 3x10")
        XCTAssertTrue(row.waitForExistence(timeout: 20))
        row.tap()

        XCTAssertTrue(app.staticTexts["UI Test 3x10"].waitForExistence(timeout: 20))
        app.buttons["playerControls.primary"].tap()

        let progress = app.staticTexts["currentStep.progressText"]
        XCTAssertTrue(progress.waitForExistence(timeout: 20))
        XCTAssertEqual(progress.label, "SET 1/3 · ROUND 1/10")

        // The upcoming strip previews a few steps ahead, and a Work chip
        // among them shows its own round number.
        XCTAssertTrue(element("upcomingStrip").waitForExistence(timeout: 10))
        let upcomingWorkChip = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS 'R2/10'"))
            .firstMatch
        XCTAssertTrue(upcomingWorkChip.waitForExistence(timeout: 10), "An upcoming Work chip should preview its round number")

        // Round progress is only shown on the *active* display while a work
        // step is playing — skipping into the Rest step should hide it.
        app.buttons["playerControls.skipForward"].tap()
        Thread.sleep(forTimeInterval: 1)
        XCTAssertFalse(app.staticTexts["currentStep.progressText"].exists, "Round badge should be hidden during rest")
    }

    func testSwipeToDeleteRemovesWorkout() {
        let row = createWorkout(named: "UI Test Deletable")
        row.swipeLeft()
        // The revealed swipe-action button isn't a descendant of the row's
        // own (now-stale) element reference — look it up fresh, globally.
        let deleteButton = app.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 20))
        deleteButton.tap()
        XCTAssertFalse(element("hiitLibrary.workoutRow.UI Test Deletable").exists)
    }
}
