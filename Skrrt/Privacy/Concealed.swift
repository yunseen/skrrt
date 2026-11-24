import SwiftUI

private struct Concealed: ViewModifier {
    @Environment(Settings.self) private var settings
    @State private var isRevealed = false
    @State private var resetTask: Task<Void, Never>?

    private let revealDuration: Duration = .seconds(5)

    func body(content: Content) -> some View {
        let isHidden = settings.hidesAddresses && !isRevealed
        content
            .opacity(isHidden ? 0 : 1)
            .blur(radius: isHidden ? 6 : 0)
            .overlay {
                if isHidden {
                    DotField().transition(.opacity)
                }
            }
            .animation(.smooth(duration: 0.4), value: isHidden)
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.4).onEnded { _ in reveal() },
                including: isHidden ? .gesture : .none
            )
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
