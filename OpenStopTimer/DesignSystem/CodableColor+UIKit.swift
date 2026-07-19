import SwiftUI
import UIKit
import OpenStopTimerKit

/// Bridges SwiftUI's `Color` (as produced by a `ColorPicker`) back into the
/// UI-free `CodableColor` the Kit models store. Lives in the app target,
/// not the package, so the package doesn't need a UIKit dependency.
extension CodableColor {
    init(_ color: Color) {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        self.init(red: Double(red), green: Double(green), blue: Double(blue), opacity: Double(alpha))
    }
}
