import SwiftUI
import CatchCore

/// Onboarding preview page showing the breed collection tracker.
/// Displays a mock grid of breed cards with rarity indicators.
struct OnboardingCollectionPreview: View {

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: CatchSpacing.space24) {
                    headerSection
                    mockCollectionGrid
                    progressBadge
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
            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: 48))
                .foregroundStyle(CatchTheme.primary)
                .accessibilityHidden(true)

            Text(CatchStrings.OnboardingTour.collectionTitle)
                .font(.title2.weight(.bold))
                .foregroundStyle(CatchTheme.textPrimary)
                .multilineTextAlignment(.center)

            Text(CatchStrings.OnboardingTour.collectionSubtitle)
                .font(.subheadline)
                .foregroundStyle(CatchTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(CatchSpacing.space4)
        }
    }

    // MARK: - Mock Grid

    private var mockCollectionGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: CatchSpacing.space12),
            GridItem(.flexible(), spacing: CatchSpacing.space12),
            GridItem(.flexible(), spacing: CatchSpacing.space12)
        ]

        return LazyVGrid(columns: columns, spacing: CatchSpacing.space12) {
            discoveredCard(
                name: CatchStrings.OnboardingTour.collectionMockBreedA,
                image: "OnboardingSteven",
                rarity: CatchStrings.BreedLog.rarityCommon
            )
            discoveredCard(
                name: CatchStrings.OnboardingTour.collectionMockBreedB,
                image: "OnboardingGarfield",
                rarity: CatchStrings.BreedLog.rarityUncommon
            )
            discoveredCard(
                name: CatchStrings.OnboardingTour.collectionMockBreedC,
                image: "OnboardingOdie",
                rarity: CatchStrings.BreedLog.rarityRare
            )
            undiscoveredCard
            undiscoveredCard
            undiscoveredCard
        }
    }

    private func discoveredCard(name: String, image: String, rarity: String) -> some View {
        VStack(spacing: CatchSpacing.space6) {
            Image(image)
                .resizable()
                .scaledToFill()
                .frame(height: 70)
                .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusSmall))

            Text(name)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(CatchTheme.textPrimary)
                .lineLimit(1)

            rarityBadge(text: rarity, isDiscovered: true)
        }
        .padding(CatchSpacing.space8)
        .background(CatchTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusSmall))
        .shadow(
            color: .black.opacity(CatchTheme.cardShadowOpacity),
            radius: CatchTheme.cardShadowRadius,
            y: CatchTheme.cardShadowY
        )
    }

    private var undiscoveredCard: some View {
        VStack(spacing: CatchSpacing.space6) {
            RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusSmall)
                .fill(CatchTheme.textSecondary.opacity(0.08))
                .frame(height: 70)
                .overlay {
                    Image(systemName: "questionmark")
                        .font(.title2)
                        .foregroundStyle(CatchTheme.textSecondary.opacity(0.3))
                }

            Text(CatchStrings.BreedLog.undiscoveredPlaceholder)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(CatchTheme.textSecondary.opacity(0.5))

            rarityBadge(text: "???", isDiscovered: false)
        }
        .padding(CatchSpacing.space8)
        .background(CatchTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusSmall))
        .opacity(0.5)
    }

    // MARK: - Progress

    private var progressBadge: some View {
        Text(CatchStrings.OnboardingTour.collectionMockDiscovered)
            .font(.caption.weight(.medium))
            .foregroundStyle(CatchTheme.accessibleTextOrange)
            .padding(.horizontal, CatchSpacing.space12)
            .padding(.vertical, CatchSpacing.space6)
            .background(CatchTheme.primary.opacity(0.12))
            .clipShape(Capsule())
    }

    // MARK: - Helpers

    private func rarityBadge(text: String, isDiscovered: Bool) -> some View {
        Text(text)
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(isDiscovered ? CatchTheme.accessibleTextOrange : CatchTheme.textSecondary.opacity(0.4))
            .textCase(.uppercase)
    }
}
