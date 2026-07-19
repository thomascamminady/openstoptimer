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
    /// it, returning to the library. The default new-workout already has one
    /// Work step, so this exercises rename, "add step via menu", and save.
    @discardableResult
    private func createWorkout(named name: String) -> XCUIElement {
        openHIITLibrary()
        app.buttons["hiitLibrary.addButton"].tap()

        let nameField = app.textFields["hiitEditor.nameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 20))
        replaceText(in: nameField, with: name)

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

        XCTAssertTrue(app.navigationBars["UI Test Tabata"].waitForExistence(timeout: 20))

        // Not started yet: summary list + a Start (play) button, no skip controls.
        XCTAssertFalse(app.buttons["playerControls.skipForward"].exists)
        app.buttons["playerControls.primary"].tap()

        let currentName = app.staticTexts["currentNextPanel.currentName"]
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

    func testSwipeToDeleteRemovesWorkout() {
        let row = createWorkout(named: "UI Test Deletable")
        row.swipeLeft()
        let deleteButton = row.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 20))
        deleteButton.tap()
        XCTAssertFalse(element("hiitLibrary.workoutRow.UI Test Deletable").exists)
    }
}
