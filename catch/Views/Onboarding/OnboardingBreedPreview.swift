import SwiftUI
import CatchCore

/// Onboarding preview page showing breed prediction.
/// Reuses the real BreedPredictionCard to show what the user will see when logging.
struct OnboardingBreedPreview: View {

    private let samplePredictions: [BreedPrediction] = [
        BreedPrediction(breed: "Orange Tabby", rawIdentifier: "orange_tabby", confidence: 0.87),
        BreedPrediction(breed: "Maine Coon", rawIdentifier: "maine_coon", confidence: 0.10),
        BreedPrediction(breed: "British Shorthair", rawIdentifier: "british_shorthair", confidence: 0.03)
    ]

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: CatchSpacing.space24) {
                    headerSection

                    BreedPredictionCard(
                        predictions: samplePredictions,
                        isClassifying: false,
                        onSelect: { _ in },
                        onDismiss: { }
                    )
                    .allowsHitTesting(false)
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
}
