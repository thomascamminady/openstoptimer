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
