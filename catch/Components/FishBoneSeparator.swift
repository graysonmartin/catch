import SwiftUI

/// A tiny decorative fish skeleton, used between icon and text in empty states.
struct FishBoneSeparator: View {
    var color: Color = CatchTheme.textSecondary.opacity(0.2)

    var body: some View {
        FishBoneShape()
            .stroke(color, style: StrokeStyle(lineWidth: 1, lineCap: .round))
            .frame(width: 32, height: 10)
    }
}

private struct FishBoneShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let midY = rect.midY
        let headX = rect.minX + 4
        let tailX = rect.maxX - 3

        // Head — small triangle pointing left
        path.move(to: CGPoint(x: headX, y: midY - 3))
        path.addLine(to: CGPoint(x: rect.minX, y: midY))
        path.addLine(to: CGPoint(x: headX, y: midY + 3))

        // Spine
        path.move(to: CGPoint(x: headX, y: midY))
        path.addLine(to: CGPoint(x: tailX, y: midY))

        // Ribs — 3 pairs of small angled lines
        let ribSpacing = (tailX - headX) / 4
        for i in 1...3 {
            let x = headX + ribSpacing * CGFloat(i)
            path.move(to: CGPoint(x: x, y: midY))
            path.addLine(to: CGPoint(x: x - 2, y: midY - 3))
            path.move(to: CGPoint(x: x, y: midY))
            path.addLine(to: CGPoint(x: x - 2, y: midY + 3))
        }

        // Tail — V shape
        path.move(to: CGPoint(x: tailX, y: midY - 3))
        path.addLine(to: CGPoint(x: tailX, y: midY))
        path.addLine(to: CGPoint(x: tailX, y: midY + 3))

        return path
    }
}
