import SwiftUI

/// Glossy blue capsule with an up arrow, shown next to the search field once text is typed.
struct SearchGoButton: View {
    let action: () -> Void

    private let core = Color(red: 0.27, green: 0.76, blue: 1.0)
    private let mid = Color(red: 0.60, green: 0.84, blue: 1.0)
    private let edge = Color(red: 0.80, green: 0.92, blue: 1.0)

    var body: some View {
        Button(action: action) {
            ZStack {
                Capsule()
                    .fill(
                        RadialGradient(
                            colors: [core, mid, edge],
                            center: .center,
                            startRadius: 2,
                            endRadius: 54
                        )
                    )
                Capsule()
                    .strokeBorder(core.opacity(0.55), lineWidth: 5)
                    .padding(2.5)
                    .blur(radius: 2)
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.95), core, .white.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.5
                    )
                Image(systemName: "arrow.up")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(color: core, radius: 6)
            }
            .frame(width: 78, height: 52)
            .shadow(color: core.opacity(0.45), radius: 10, y: 4)
        }
        .buttonStyle(PressStyle())
        .accessibilityLabel(Text("Go"))
    }
}
