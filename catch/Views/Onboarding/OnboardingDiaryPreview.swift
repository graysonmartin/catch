import SwiftUI
import CatchCore

/// Onboarding preview page showing the encounter diary.
/// Displays a mock feed card to illustrate the chronological log.
struct OnboardingDiaryPreview: View {

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: CatchSpacing.space24) {
                    headerSection
                    mockDiaryCard
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
            Image(systemName: "book.pages.fill")
                .font(.system(size: 48))
                .foregroundStyle(CatchTheme.primary)
                .accessibilityHidden(true)

            Text(CatchStrings.OnboardingTour.diaryTitle)
                .font(.title2.weight(.bold))
                .foregroundStyle(CatchTheme.textPrimary)
                .multilineTextAlignment(.center)

            Text(CatchStrings.OnboardingTour.diarySubtitle)
                .font(.subheadline)
                .foregroundStyle(CatchTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(CatchSpacing.space4)
        }
    }

    // MARK: - Mock Diary Card

    private var mockDiaryCard: some View {
        VStack(alignment: .leading, spacing: CatchSpacing.space12) {
            cardHeader
            mockPhotoStrip
            cardMetadata
            mockInteractionBar
        }
        .padding(CatchSpacing.space16)
        .background(CatchTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadius))
        .shadow(
            color: .black.opacity(CatchTheme.cardShadowOpacity),
            radius: CatchTheme.cardShadowRadius,
            y: CatchTheme.cardShadowY
        )
    }

    private var cardHeader: some View {
        HStack(spacing: CatchSpacing.space12) {
            // Cat avatar
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
                    .font(.headline)
                    .foregroundStyle(CatchTheme.textPrimary)

                HStack(spacing: CatchSpacing.space4) {
                    encounterPill(
                        text: CatchStrings.OnboardingTour.breedMockPill,
                        isActive: true
                    )
                }
            }

            Spacer()

            Text(CatchStrings.OnboardingTour.diaryMockDate)
                .font(.caption)
                .foregroundStyle(CatchTheme.textSecondary)
        }
    }

    private var mockPhotoStrip: some View {
        RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusSmall)
            .fill(
                LinearGradient(
                    colors: [
                        CatchTheme.primary.opacity(0.2),
                        CatchTheme.secondary.opacity(0.35)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 120)
            .overlay {
                Image(systemName: "cat.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(CatchTheme.primary.opacity(0.5))
            }
    }

    private var cardMetadata: some View {
        VStack(alignment: .leading, spacing: CatchSpacing.space4) {
            HStack(spacing: CatchSpacing.space6) {
                Image(systemName: "pawprint.fill")
                    .frame(width: 16, alignment: .center)
                    .accessibilityHidden(true)
                Text(CatchStrings.OnboardingTour.breedMockResult)
            }
            .font(.subheadline)
            .foregroundStyle(CatchTheme.textSecondary)

            HStack(spacing: CatchSpacing.space6) {
                Image(systemName: "mappin.circle.fill")
                    .frame(width: 16, alignment: .center)
                    .accessibilityHidden(true)
                Text(CatchStrings.OnboardingTour.diaryMockLocation)
            }
            .font(.subheadline)
            .foregroundStyle(CatchTheme.textSecondary)

            Text(CatchStrings.OnboardingTour.diaryMockNote)
                .font(.subheadline)
                .foregroundStyle(CatchTheme.textPrimary)
                .lineLimit(2)
        }
    }

    private var mockInteractionBar: some View {
        HStack(spacing: CatchSpacing.space20) {
            HStack(spacing: CatchSpacing.space4) {
                Image(systemName: "heart")
                    .font(.subheadline)
                Text("3")
                    .font(.caption)
            }
            .foregroundStyle(CatchTheme.textSecondary)

            HStack(spacing: CatchSpacing.space4) {
                Image(systemName: "bubble.right")
                    .font(.subheadline)
                Text("1")
                    .font(.caption)
            }
            .foregroundStyle(CatchTheme.textSecondary)

            Spacer()
        }
    }

    // MARK: - Helpers

    private func encounterPill(text: String, isActive: Bool) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(isActive ? CatchTheme.accessibleTextOrange : CatchTheme.textSecondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        isActive
                            ? CatchTheme.primary.opacity(0.15)
                            : CatchTheme.textSecondary.opacity(0.1)
                    )
            )
    }
}
