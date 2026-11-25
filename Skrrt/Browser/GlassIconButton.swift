import SwiftUI

/// A round Liquid Glass button. The whole circle is tappable and the glass reacts to touch.
struct GlassIconButton: View {
    let symbol: String
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: Metrics.symbolSize, weight: .semibold))
                .frame(width: Metrics.controlSize, height: Metrics.controlSize)
                .contentShape(Circle())
                .glassEffect(.regular.interactive(isEnabled), in: .circle)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
    }
}
