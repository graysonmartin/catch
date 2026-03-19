import SwiftUI
import CoreLocation
import CatchCore

/// Location permissions step of the new-user walkthrough.
/// Reuses the same `OnboardingLocationManager` from the intro onboarding.
struct WalkthroughLocationStep: View {
    @State private var locationManager = OnboardingLocationManager()

    var body: some View {
        VStack(spacing: CatchSpacing.space24) {
            Spacer()

            iconSection

            textSection

            permissionButton

            Spacer()
            Spacer()
        }
        .padding(.horizontal, CatchSpacing.space32)
    }

    // MARK: - Subviews

    private var iconSection: some View {
        Image(systemName: "location.circle.fill")
            .font(.system(size: 72))
            .foregroundStyle(CatchTheme.primary)
    }

    private var textSection: some View {
        VStack(spacing: CatchSpacing.space12) {
            Text(CatchStrings.Walkthrough.locationTitle)
                .font(.title2.weight(.bold))
                .foregroundStyle(CatchTheme.textPrimary)

            Text(CatchStrings.Walkthrough.locationSubtitle)
                .font(.subheadline)
                .foregroundStyle(CatchTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(CatchSpacing.space4)

            Text(CatchStrings.Walkthrough.locationReassurance)
                .font(.caption)
                .foregroundStyle(CatchTheme.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(CatchSpacing.space4)
                .padding(.top, CatchSpacing.space4)
        }
    }

    @ViewBuilder
    private var permissionButton: some View {
        if !locationManager.hasRequested {
            Button {
                locationManager.requestPermission()
            } label: {
                HStack {
                    Image(systemName: "location.fill")
                    Text(CatchStrings.Walkthrough.enableLocation)
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(CatchTheme.primary)
                .padding(.horizontal, CatchSpacing.space20)
                .padding(.vertical, CatchSpacing.space10)
                .background(CatchTheme.primary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        } else {
            HStack(spacing: CatchSpacing.space6) {
                Image(systemName: locationManager.wasGranted ? "checkmark.circle.fill" : "info.circle.fill")
                    .foregroundStyle(locationManager.wasGranted ? .green : CatchTheme.textSecondary)
                Text(locationManager.wasGranted
                     ? CatchStrings.Walkthrough.locationEnabled
                     : CatchStrings.Walkthrough.locationSkipped)
                    .font(.caption)
                    .foregroundStyle(CatchTheme.textSecondary)
            }
        }
    }
}
