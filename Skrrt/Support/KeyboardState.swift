import Observation
import UIKit

/// Tells the interface whether the software keyboard is on screen, so the toolbar can step aside.
@MainActor
@Observable
final class KeyboardState {
    private(set) var isVisible = false
    @ObservationIgnored private var tokens: [NSObjectProtocol] = []

    init() {
        let center = NotificationCenter.default
        tokens.append(center.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.isVisible = true }
        })
        tokens.append(center.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.isVisible = false }
        })
    }
}
