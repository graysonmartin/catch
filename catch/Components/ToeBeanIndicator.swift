import UIKit

/// Generates a tiny toe-bean cluster image for use as a tab bar selection indicator.
enum ToeBeanIndicator {
    static func image(color: UIColor = CatchTheme.primaryUIColor) -> UIImage {
        let size = CGSize(width: 16, height: 10)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { ctx in
            let cg = ctx.cgContext
            color.withAlphaComponent(0.5).setFill()

            // Main pad — wider oval at bottom
            let mainPad = CGRect(x: 4, y: 5, width: 8, height: 5)
            cg.fillEllipse(in: mainPad)

            // Three toe beans above — small circles
            let toeY: CGFloat = 1
            let toeSize: CGFloat = 3.5
            let toePositions: [CGFloat] = [2.5, 6.25, 10]

            for x in toePositions {
                cg.fillEllipse(in: CGRect(x: x, y: toeY, width: toeSize, height: toeSize))
            }
        }
        .withRenderingMode(.alwaysOriginal)
    }
}
