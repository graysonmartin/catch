import SwiftUI
import CatchCore

/// Onboarding preview page showing the encounter diary.
/// Mimics the compact row style seen on the profile (RemoteDiaryEntryRow).
struct OnboardingDiaryPreview: View {

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: CatchSpacing.space24) {
                    headerSection
                    mockDiaryRows
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

    // MARK: - Mock Diary Rows

    private var mockDiaryRows: some View {
        VStack(spacing: CatchSpacing.space8) {
            mockRow(
                name: CatchStrings.OnboardingTour.diaryMockCatA,
                image: "OnboardingSteven",
                isNew: true,
                location: CatchStrings.OnboardingTour.diaryMockLocationA,
                likes: 3,
                comments: 1
            )
            mockRow(
                name: CatchStrings.OnboardingTour.diaryMockCatB,
                image: "OnboardingGarfield",
                isNew: false,
                location: CatchStrings.OnboardingTour.diaryMockLocationB,
                likes: 1,
                comments: 0
            )
            mockRow(
                name: CatchStrings.OnboardingTour.diaryMockCatC,
                image: "OnboardingOdie",
                isNew: true,
                location: CatchStrings.OnboardingTour.diaryMockLocationC,
                likes: 5,
                comments: 2
            )
        }
    }

    private func mockRow(
        name: String,
        image: String,
        isNew: Bool,
        location: String,
        likes: Int,
        comments: Int
    ) -> some View {
        HStack(alignment: .top, spacing: CatchSpacing.space12) {
            Image(image)
                .resizable()
                .scaledToFill()
                .frame(width: 48, height: 48)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: CatchSpacing.space2) {
                HStack(spacing: CatchSpacing.space4) {
                    Text(name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CatchTheme.textPrimary)
                        .lineLimit(1)

                    encounterPill(isNew: isNew)

                    Spacer()
                }

                HStack {
                    EngagementIndicator(likeCount: likes, commentCount: comments)
                    Spacer()
                    Label(location, systemImage: "mappin")
                        .font(.caption)
                        .foregroundStyle(CatchTheme.textSecondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, CatchSpacing.space4)
        .padding(.horizontal, CatchSpacing.space12)
        .background(CatchTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusTight))
        .shadow(
            color: .black.opacity(CatchTheme.cardShadowOpacity),
            radius: CatchTheme.cardShadowRadius,
            y: CatchTheme.cardShadowY
        )
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
