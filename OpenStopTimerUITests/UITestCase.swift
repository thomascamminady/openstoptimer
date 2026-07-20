import XCTest

/// Base class for all UI tests: launches with `-uiTestingReset`, which tells
/// `AppState` to wipe any saved workouts/settings on launch so every test
/// starts from a clean, deterministic slate regardless of what a previous
/// test run left behind.
class UITestCase: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments = ["-uiTestingReset"]
        app.launch()
    }

    /// Looks up an element by accessibility identifier regardless of its
    /// concrete XCUIElementType — SwiftUI doesn't guarantee whether a given
    /// view becomes a button/cell/other in the accessibility tree, so tests
    /// should query by identifier alone rather than by (identifier, type).
    func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    /// The wheel picker's identifier lands on its container in the
    /// accessibility tree, not on the underlying `UIPickerView` wheel
    /// sub-element XCUITest actually interacts with — so look the wheel up
    /// as a descendant of that identified container.
    func pickerWheel(_ containerIdentifier: String) -> XCUIElement {
        element(containerIdentifier).pickerWheels.firstMatch
    }

    /// Finds a `Stepper` by its visible label prefix (e.g. "Sets:"). Its
    /// +/- controls are child buttons identified as
    /// "<stepperIdentifier>-Increment"/"-Decrement", with labels like
    /// "Sets: 1, Increment" — not the bare "Increment"/"Decrement" you'd
    /// naively guess.
    func stepper(labeled prefix: String) -> XCUIElement {
        app.steppers.matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
    }

    /// A `Toggle` inside a `Form` row exposes one accessibility element
    /// spanning the full row, but `.tap()`'s default center-point tap can
    /// land on non-interactive padding rather than the switch — tapping
    /// near the trailing edge (where the switch control actually renders)
    /// is what reliably registers.
    func tapSwitch(_ element: XCUIElement) {
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
    }

    /// `Form`/`List` lazily instantiate off-screen rows, so a target further
    /// down than the current scroll position may not exist in the
    /// accessibility tree yet — swipe up until it does (or give up).
    func scrollDownUntilVisible(_ element: XCUIElement, maxSwipes: Int = 8) {
        var attempts = 0
        while !element.exists, attempts < maxSwipes {
            app.swipeUp()
            attempts += 1
        }
    }

    /// Navigates Home -> the named mode card, asserting the destination's
    /// navigation title appears.
    @discardableResult
    func openMode(cardIdentifier: String, expectedTitle: String) -> XCUIElement {
        let card = element(cardIdentifier)
        XCTAssertTrue(card.waitForExistence(timeout: 5), "\(cardIdentifier) card should exist on Home")
        card.tap()
        let title = app.navigationBars[expectedTitle].firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 5), "Should navigate to \(expectedTitle)")
        return title
    }

    /// BigTimeText exposes the raw on-screen digits via `.value` (its
    /// `.label` is intentionally a spoken-friendly VoiceOver phrase instead).
    func waitForValue(_ identifier: String, toEqual expected: String, timeout: TimeInterval = 5) {
        let target = element(identifier)
        let predicate = NSPredicate(format: "value == %@", expected)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: target)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed, "\(identifier) never showed '\(expected)' (last: '\(target.value ?? "nil")')")
    }
}
