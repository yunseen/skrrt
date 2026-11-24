import SwiftUI

struct DotField: View {
    private let step: CGFloat = 6
    private let dot: CGFloat = 3

    var body: some View {
        TimelineView(.animation) { context in
            Canvas { graphics, size in
                let time = context.date.timeIntervalSinceReferenceDate
                let columns = max(1, Int(size.width / step))
                let rows = max(1, Int(size.height / step))
                let originX = (size.width - CGFloat(columns) * step) / 2 + (step - dot) / 2
                let originY = (size.height - CGFloat(rows) * step) / 2 + (step - dot) / 2
                for row in 0..<rows {
                    for column in 0..<columns {
                        let speed = 1.1 + Double((column + row) % 5) * 0.23
                        let phase = Double(column * 7 + row * 13)
                        let level = 0.5 + 0.5 * sin(time * speed + phase)
                        let rect = CGRect(
                            x: originX + CGFloat(column) * step,
                            y: originY + CGFloat(row) * step,
                            width: dot,
                            height: dot
                        )
                        graphics.fill(Path(ellipseIn: rect), with: .color(.primary.opacity(0.12 + 0.38 * level)))
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}
