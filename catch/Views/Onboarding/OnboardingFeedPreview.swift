import SwiftUI
import CatchCore

/// Onboarding preview page showing the social feed.
/// Reuses the current diary-style mock card to preview the feed experience.
struct OnboardingFeedPreview: View {

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: CatchSpacing.space24) {
                    headerSection
                    mockFeedCard
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
            Image(systemName: "list.bullet.below.rectangle")
                .font(.system(size: 48))
                .foregroundStyle(CatchTheme.primary)
                .accessibilityHidden(true)

            Text(CatchStrings.OnboardingTour.feedTitle)
                .font(.title2.weight(.bold))
                .foregroundStyle(CatchTheme.textPrimary)
                .multilineTextAlignment(.center)

            Text(CatchStrings.OnboardingTour.feedSubtitle)
                .font(.subheadline)
                .foregroundStyle(CatchTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(CatchSpacing.space4)
        }
    }

    // MARK: - Mock Feed Card

    private var mockFeedCard: some View {
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
            Image("OnboardingSteven")
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: CatchSpacing.space2) {
                Text(CatchStrings.OnboardingTour.feedMockName)
                    .font(.headline)
                    .foregroundStyle(CatchTheme.textPrimary)

                HStack(spacing: CatchSpacing.space4) {
                    encounterPill(isNew: true)
                }
            }

            Spacer()

            Text(CatchStrings.OnboardingTour.feedMockDate)
                .font(.caption)
                .foregroundStyle(CatchTheme.textSecondary)
        }
    }

    private var mockPhotoStrip: some View {
        Image("OnboardingSteven")
            .resizable()
            .scaledToFill()
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusSmall))
    }

    private var cardMetadata: some View {
        VStack(alignment: .leading, spacing: CatchSpacing.space4) {
            HStack(spacing: CatchSpacing.space6) {
                Image(systemName: "pawprint.fill")
                    .frame(width: 16, alignment: .center)
                    .accessibilityHidden(true)
                Text(CatchStrings.OnboardingTour.feedMockBreed)
            }
            .font(.subheadline)
            .foregroundStyle(CatchTheme.textSecondary)

            HStack(spacing: CatchSpacing.space6) {
                Image(systemName: "mappin.circle.fill")
                    .frame(width: 16, alignment: .center)
                    .accessibilityHidden(true)
                Text(CatchStrings.OnboardingTour.feedMockLocation)
            }
            .font(.subheadline)
            .foregroundStyle(CatchTheme.textSecondary)

            Text(CatchStrings.OnboardingTour.feedMockNote)
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

    private func encounterPill(isNew: Bool) -> some View {
        Text(isNew ? CatchStrings.Feed.pillNew : CatchStrings.Feed.pillRepeat)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(isNew ? CatchTheme.primary : CatchTheme.textSecondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isNew
                        ? CatchTheme.primary.opacity(0.15)
                        : CatchTheme.textSecondary.opacity(0.1))
            )
    }
}
