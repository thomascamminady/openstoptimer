import SwiftUI
import UIKit

/// Keeps the device from auto-locking while a timer session is on screen —
/// timers are very commonly used propped up on a counter or gym floor.
private struct KeepScreenAwakeModifier: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .onAppear { UIApplication.shared.isIdleTimerDisabled = isActive }
            .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
            .onChange(of: isActive) { _, newValue in
                UIApplication.shared.isIdleTimerDisabled = newValue
            }
    }
}

extension View {
    func keepScreenAwake(while isActive: Bool) -> some View {
        modifier(KeepScreenAwakeModifier(isActive: isActive))
    }
}
