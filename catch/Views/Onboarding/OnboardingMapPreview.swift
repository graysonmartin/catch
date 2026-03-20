import SwiftUI
import CatchCore

/// Onboarding preview page showing the cat map feature.
/// Displays mock map pins to illustrate location tracking.
struct OnboardingMapPreview: View {

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: CatchSpacing.space24) {
                    headerSection
                    mockMap
                }
                .padding(.horizontal, CatchSpacing.space32)
                .frame(maxWidth: .infinity, minHeight: geo.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: CatchSpacing.space12) {
            Image(systemName: "map.fill")
                .font(.system(size: 48))
                .foregroundStyle(CatchTheme.primary)
                .accessibilityHidden(true)

            Text(CatchStrings.OnboardingTour.mapTitle)
                .font(.title2.weight(.bold))
                .foregroundStyle(CatchTheme.textPrimary)
                .multilineTextAlignment(.center)

            Text(CatchStrings.OnboardingTour.mapSubtitle)
                .font(.subheadline)
                .foregroundStyle(CatchTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(CatchSpacing.space4)
        }
    }

    // MARK: - Mock Map

    private var mockMap: some View {
        ZStack {
            // Map background
            RoundedRectangle(cornerRadius: CatchTheme.cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.85, green: 0.91, blue: 0.82),
                            Color(red: 0.90, green: 0.94, blue: 0.88)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 220)
                .overlay {
                    // Mock street grid
                    mockStreetGrid
                }

            // Pins
            pinView(
                name: CatchStrings.OnboardingTour.mapMockCatA,
                offset: CGSize(width: -40, height: -30)
            )
            pinView(
                name: CatchStrings.OnboardingTour.mapMockCatB,
                offset: CGSize(width: 50, height: 20)
            )
            pinView(
                name: CatchStrings.OnboardingTour.mapMockCatC,
                offset: CGSize(width: -10, height: 55)
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadius))
        .shadow(
            color: .black.opacity(CatchTheme.cardShadowOpacity),
            radius: CatchTheme.cardShadowRadius,
            y: CatchTheme.cardShadowY
        )
    }

    private var mockStreetGrid: some View {
        Canvas { context, size in
            let lineColor = Color.gray.opacity(0.15)

            // Horizontal lines
            for yFraction in stride(from: 0.2, through: 0.8, by: 0.3) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: size.height * yFraction))
                path.addLine(to: CGPoint(x: size.width, y: size.height * yFraction))
                context.stroke(path, with: .color(lineColor), lineWidth: 1.5)
            }

            // Vertical lines
            for xFraction in stride(from: 0.25, through: 0.75, by: 0.25) {
                var path = Path()
                path.move(to: CGPoint(x: size.width * xFraction, y: 0))
                path.addLine(to: CGPoint(x: size.width * xFraction, y: size.height))
                context.stroke(path, with: .color(lineColor), lineWidth: 1.5)
            }
        }
    }

    private func pinView(name: String, offset: CGSize) -> some View {
        VStack(spacing: CatchSpacing.space2) {
            // Pin head
            Circle()
                .fill(CatchTheme.primary)
                .frame(width: 28, height: 28)
                .overlay {
                    Image(systemName: "cat.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.white)
                }
                .shadow(color: .black.opacity(0.15), radius: 3, y: 2)

            // Pin label
            Text(name)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(CatchTheme.textPrimary)
                .padding(.horizontal, CatchSpacing.space4)
                .padding(.vertical, 1)
                .background(
                    Capsule()
                        .fill(CatchTheme.cardBackground.opacity(0.9))
                )
        }
        .offset(offset)
    }
}
