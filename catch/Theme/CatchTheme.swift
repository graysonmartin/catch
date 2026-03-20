import SwiftUI
import UIKit

enum CatchTheme {

    // MARK: - Colors

    static let primary = Color(red: 1.0, green: 0.6, blue: 0.2)       // warm orange
    static let secondary = Color(red: 1.0, green: 0.8, blue: 0.6)     // peach

    /// Darkened orange that meets WCAG AA 4.5:1 contrast on warm off-white background.
    /// Use for small text rendered in orange on light backgrounds.
    static let accessibleTextOrange = Color(red: 0.70, green: 0.33, blue: 0.0)

    /// Warm off-white in light mode; system dark background in dark mode.
    static let background = Color(uiColor: .catchBackground)

    /// White in light mode; elevated surface in dark mode.
    static let cardBackground = Color(uiColor: .catchCardBackground)

    /// Dark brown in light mode; `.label` (white) in dark mode.
    static let textPrimary = Color(.label)

    /// Muted brown in light mode; `.secondaryLabel` in dark mode.
    static let textSecondary = Color(.secondaryLabel)

    /// UIColor version of `primary` for UIKit contexts (MapKit annotations, etc.)
    static let primaryUIColor = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)

    /// UIColor version for remote (friend's) cat pins — muted brown to distinguish from own cats
    static let remotePinUIColor = UIColor(red: 0.5, green: 0.4, blue: 0.35, alpha: 1.0)

    /// SwiftUI Color version for remote cat pins
    static let remotePinColor = Color(red: 0.5, green: 0.4, blue: 0.35)

    // MARK: - Corner Radii

    static let cornerRadius: CGFloat = 16
    static let cornerRadiusSmall: CGFloat = 12
    static let cornerRadiusTight: CGFloat = 10

    // MARK: - Card Shadow

    static let cardShadowRadius: CGFloat = 4
    static let cardShadowY: CGFloat = 2
    static let cardShadowOpacity: Double = 0.05

    // MARK: - Accessibility

    /// Apple HIG minimum tap target size (44x44pt)
    static let minTapTarget: CGFloat = 44

    // MARK: - Photo

    static let jpegCompressionQuality: CGFloat = 0.7
    static let maxPhotoSelection = 5
}

// MARK: - Adaptive UIColors

extension UIColor {

    /// Warm off-white in light mode; `systemBackground` in dark mode.
    static let catchBackground = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? .systemBackground
            : UIColor(red: 0.98, green: 0.96, blue: 0.93, alpha: 1.0)
    }

    /// Pure white in light mode; `secondarySystemBackground` in dark mode.
    static let catchCardBackground = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? .secondarySystemBackground
            : .white
    }
}
