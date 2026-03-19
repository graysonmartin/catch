import SwiftUI
import CatchCore

/// First step of the new-user walkthrough. Greets the user after sign-up.
struct WalkthroughWelcomeStep: View {

    var body: some View {
        VStack(spacing: CatchSpacing.space24) {
            Spacer()

            iconSection

            textSection

            Spacer()
            Spacer()
        }
        .padding(.horizontal, CatchSpacing.space32)
    }

    // MARK: - Subviews

    private var iconSection: some View {
        Image(systemName: "pawprint.fill")
            .font(.system(size: 72))
            .foregroundStyle(CatchTheme.primary)
    }

    private var textSection: some View {
        VStack(spacing: CatchSpacing.space12) {
            Text(CatchStrings.Walkthrough.welcomeTitle)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(CatchTheme.textPrimary)

            Text(CatchStrings.Walkthrough.welcomeSubtitle)
                .font(.title3)
                .foregroundStyle(CatchTheme.textSecondary)
                .multilineTextAlignment(.center)

            Text(CatchStrings.Walkthrough.welcomeDetail)
                .font(.subheadline)
                .foregroundStyle(CatchTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(CatchSpacing.space4)
                .padding(.top, CatchSpacing.space4)
        }
    }
}
