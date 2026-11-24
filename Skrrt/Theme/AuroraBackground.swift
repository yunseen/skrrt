import SwiftUI

struct AuroraBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            MeshGradient(width: 3, height: 3, points: points(at: t), colors: colors)
        }
    }

    private var colors: [Color] {
        let base: Color = scheme == .dark ? .black : .white
        let glow = Palette.blue.opacity(scheme == .dark ? 0.55 : 0.28)
        let soft = Palette.blue.opacity(scheme == .dark ? 0.22 : 0.12)
        let deep = scheme == .dark ? Palette.deepBlue.opacity(0.6) : Palette.blue.opacity(0.08)
        return [base, base, base, deep, glow, deep, base, soft, base]
    }

    private func points(at t: Double) -> [SIMD2<Float>] {
        let x = Float(0.5 + 0.14 * sin(t * 0.55))
        let y = Float(0.5 + 0.14 * cos(t * 0.45))
        return [
            [0, 0], [0.5, 0], [1, 0],
            [0, 0.5], [x, y], [1, 0.5],
            [0, 1], [0.5, 1], [1, 1]
        ]
    }
}
