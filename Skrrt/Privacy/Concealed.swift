import SwiftUI

private struct Concealed: ViewModifier {
    @Environment(Settings.self) private var settings
    @State private var isRevealed = false
    @State private var resetTask: Task<Void, Never>?

    private let revealDuration: Duration = .seconds(5)

    func body(content: Content) -> some View {
        let isHidden = settings.hidesAddresses && !isRevealed
        if isHidden {
            content
                .opacity(0)
                .overlay { DotField().transition(.opacity) }
                .animation(.smooth(duration: 0.4), value: isHidden)
                .onLongPressGesture(minimumDuration: 0.4) { reveal() }
        } else {
            content
        }
    }

    private func reveal() {
        isRevealed = true
        resetTask?.cancel()
        resetTask = Task {
            try? await Task.sleep(for: revealDuration)
            guard !Task.isCancelled else { return }
            isRevealed = false
        }
    }
}

extension View {
    func concealed() -> some View {
        modifier(Concealed())
    }
}
