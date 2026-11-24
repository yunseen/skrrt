import SwiftUI

struct GlassIconButton: View {
    let symbol: String
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: Metrics.symbolSize, weight: .semibold))
                .frame(width: Metrics.controlSize, height: Metrics.controlSize)
                .background(.ultraThinMaterial)
        }
        .buttonStyle(PressStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
    }
}
