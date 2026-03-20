import SwiftUI

/// A small inverted-triangle cat-nose shape, used as a bullet/marker in info rows.
struct CatNoseBullet: View {
    var size: CGFloat = 8
    var color: Color = CatchTheme.primary

    var body: some View {
        CatNoseShape()
            .fill(color)
            .frame(width: size, height: size * 0.75)
    }
}

private struct CatNoseShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Rounded inverted triangle — like a cat nose
        let topLeft = CGPoint(x: rect.minX + rect.width * 0.1, y: rect.minY)
        let topRight = CGPoint(x: rect.maxX - rect.width * 0.1, y: rect.minY)
        let bottom = CGPoint(x: rect.midX, y: rect.maxY)

        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addCurve(
            to: bottom,
            control1: CGPoint(x: topRight.x + 1, y: rect.minY),
            control2: CGPoint(x: rect.maxX * 0.7, y: rect.maxY)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control1: CGPoint(x: rect.maxX * 0.3, y: rect.maxY),
            control2: CGPoint(x: topLeft.x - 1, y: rect.minY)
        )

        return path
    }
}
