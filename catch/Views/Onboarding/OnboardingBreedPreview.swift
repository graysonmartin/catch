import SwiftUI
import CatchCore

/// Onboarding preview page showing breed prediction.
/// Displays a mock cat photo with a breed classification result.
struct OnboardingBreedPreview: View {

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: CatchSpacing.space24) {
                    headerSection
                    mockCard
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
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 48))
                .foregroundStyle(CatchTheme.primary)
                .accessibilityHidden(true)

            Text(CatchStrings.OnboardingTour.breedTitle)
                .font(.title2.weight(.bold))
                .foregroundStyle(CatchTheme.textPrimary)
                .multilineTextAlignment(.center)

            Text(CatchStrings.OnboardingTour.breedSubtitle)
                .font(.subheadline)
                .foregroundStyle(CatchTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(CatchSpacing.space4)
        }
    }

    // MARK: - Mock Card

    private var mockCard: some View {
        VStack(spacing: 0) {
            mockPhoto
            breedResult
        }
        .background(CatchTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadius))
        .shadow(
            color: .black.opacity(CatchTheme.cardShadowOpacity),
            radius: CatchTheme.cardShadowRadius,
            y: CatchTheme.cardShadowY
        )
    }

    private var mockPhoto: some View {
        ZStack(alignment: .topLeading) {
            // Gradient placeholder representing a cat photo
            RoundedRectangle(cornerRadius: 0)
                .fill(
                    LinearGradient(
                        colors: [
                            CatchTheme.primary.opacity(0.3),
                            CatchTheme.secondary.opacity(0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 160)
                .overlay {
                    Image(systemName: "cat.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(CatchTheme.primary.opacity(0.6))
                }

            // NEW pill
            Text(CatchStrings.OnboardingTour.breedMockPill)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(CatchTheme.accessibleTextOrange)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(CatchTheme.primary.opacity(0.15))
                )
                .padding(CatchSpacing.space12)
        }
    }

    private var breedResult: some View {
        HStack(spacing: CatchSpacing.space12) {
            // Cat avatar circle
            Circle()
                .fill(CatchTheme.primary.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "cat.fill")
                        .font(.caption)
                        .foregroundStyle(CatchTheme.primary)
                }

            VStack(alignment: .leading, spacing: CatchSpacing.space2) {
                Text(CatchStrings.OnboardingTour.breedMockName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CatchTheme.textPrimary)

                HStack(spacing: CatchSpacing.space6) {
                    Image(systemName: "pawprint.fill")
                        .font(.caption2)
                        .foregroundStyle(CatchTheme.primary)
                    Text(CatchStrings.OnboardingTour.breedMockResult)
                        .font(.caption)
                        .foregroundStyle(CatchTheme.textSecondary)
                }
            }

            Spacer()

            Text(CatchStrings.OnboardingTour.breedMockConfidence)
                .font(.caption.weight(.medium))
                .foregroundStyle(CatchTheme.accessibleTextOrange)
                .padding(.horizontal, CatchSpacing.space8)
                .padding(.vertical, CatchSpacing.space4)
                .background(CatchTheme.primary.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(CatchSpacing.space16)
    }
}
