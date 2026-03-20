import SwiftUI

/// A decorative divider shaped like a cat tail curling to the right.
/// Drop-in replacement for `Divider()` with cat personality.
struct CatTailDivider: View {
    var color: Color = CatchTheme.textSecondary.opacity(0.2)
    var lineWidth: CGFloat = 1.2

    var body: some View {
        CatTailShape()
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .frame(height: 12)
    }
}

private struct CatTailShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let midY = rect.midY
        let curlStart = rect.width * 0.7
        let curlPeak = rect.width * 0.88
        let curlEnd = rect.width * 0.92

        // Straight-ish section with a gentle wave
        path.move(to: CGPoint(x: rect.minX, y: midY))
        path.addQuadCurve(
            to: CGPoint(x: curlStart, y: midY - 1),
            control: CGPoint(x: rect.width * 0.35, y: midY + 1.5)
        )

        // The curl — lifts up then loops back
        path.addCurve(
            to: CGPoint(x: curlEnd, y: midY - 5),
            control1: CGPoint(x: curlPeak, y: midY - 1),
            control2: CGPoint(x: rect.width * 0.95, y: midY - 8)
        )

        return path
    }
}
