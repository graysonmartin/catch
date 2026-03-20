import SwiftUI

/// A section header with three tiny whisker lines on each side of the text.
struct WhiskerSectionHeader: View {
    let text: String

    private enum Layout {
        static let whiskerLength: CGFloat = 8
        static let whiskerSpacing: CGFloat = 2.5
        static let whiskerLineWidth: CGFloat = 1
        static let sideInset: CGFloat = 6
    }

    var body: some View {
        HStack(spacing: Layout.sideInset) {
            WhiskerGroup(flipped: true)
            Text(text)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CatchTheme.textSecondary)
                .textCase(.uppercase)
            WhiskerGroup(flipped: false)
        }
    }
}

private struct WhiskerGroup: View {
    let flipped: Bool

    private enum Layout {
        static let whiskerLength: CGFloat = 8
        static let whiskerSpacing: CGFloat = 2.5
        static let whiskerLineWidth: CGFloat = 1
        static let angles: [Double] = [-15, 0, 15]
    }

    var body: some View {
        Canvas { context, size in
            let centerY = size.height / 2

            for (index, angle) in Layout.angles.enumerated() {
                let yOffset = CGFloat(index - 1) * Layout.whiskerSpacing
                let radians = angle * .pi / 180
                let actualAngle = flipped ? -radians : radians

                let startX: CGFloat = flipped ? Layout.whiskerLength : 0
                let endX: CGFloat = flipped ? 0 : Layout.whiskerLength
                let startY = centerY + yOffset
                let endY = startY + sin(actualAngle) * Layout.whiskerLength

                var path = Path()
                path.move(to: CGPoint(x: startX, y: startY))
                path.addLine(to: CGPoint(x: endX, y: endY))

                context.stroke(
                    path,
                    with: .color(CatchTheme.textSecondary.opacity(0.35)),
                    style: StrokeStyle(lineWidth: Layout.whiskerLineWidth, lineCap: .round)
                )
            }
        }
        .frame(width: Layout.whiskerLength, height: 12)
    }
}
