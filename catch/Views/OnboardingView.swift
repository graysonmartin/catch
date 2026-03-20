import SwiftUI
import CoreLocation
import CatchCore

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    @State private var locationManager = OnboardingLocationManager()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let totalPages = 6

    var body: some View {
        ZStack {
            CatchTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    OnboardingBreedPreview().tag(1)
                    OnboardingMapPreview().tag(2)
                    OnboardingDiaryPreview().tag(3)
                    OnboardingCollectionPreview().tag(4)
                    locationPage.tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: currentPage)

                bottomControls
            }
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: CatchSpacing.space24) {
            pageDots

            Button {
                if currentPage < totalPages - 1 {
                    currentPage += 1
                } else {
                    hasCompletedOnboarding = true
                }
            } label: {
                Text(currentPage == totalPages - 1 ? CatchStrings.Onboarding.letsGo : CatchStrings.Onboarding.next)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(CatchTheme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            if currentPage < totalPages - 1 {
                Button {
                    hasCompletedOnboarding = true
                } label: {
                    Text(CatchStrings.Onboarding.skip)
                        .font(.subheadline)
                        .foregroundStyle(CatchTheme.textSecondary)
                        .frame(minHeight: CatchTheme.minTapTarget)
                }
            }
        }
        .padding(.horizontal, CatchSpacing.space32)
        .padding(.bottom, CatchSpacing.space48)
    }

    private var pageDots: some View {
        HStack(spacing: CatchSpacing.space8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? CatchTheme.primary : CatchTheme.primary.opacity(0.25))
                    .frame(width: 8, height: 8)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(CatchStrings.Accessibility.onboardingPage(currentPage + 1, of: totalPages))
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: CatchSpacing.space24) {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(CatchTheme.primary)
                        .accessibilityHidden(true)

                    VStack(spacing: CatchSpacing.space12) {
                        Text(CatchStrings.Onboarding.appName)
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(CatchTheme.textPrimary)

                        Text(CatchStrings.Onboarding.subtitle)
                            .font(.title3)
                            .foregroundStyle(CatchTheme.textSecondary)

                        Text(CatchStrings.Onboarding.detail)
                            .font(.subheadline)
                            .foregroundStyle(CatchTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(CatchSpacing.space4)
                    }
                }
                .padding(.horizontal, CatchSpacing.space32)
                .frame(maxWidth: .infinity, minHeight: geo.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    // MARK: - Page 6: Location Permission

    private var locationPage: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: CatchSpacing.space24) {
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(CatchTheme.primary)
                        .accessibilityHidden(true)

                    VStack(spacing: CatchSpacing.space12) {
                        Text(CatchStrings.Onboarding.locationTitle)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(CatchTheme.textPrimary)

                        Text(CatchStrings.Onboarding.locationDescription)
                            .font(.subheadline)
                            .foregroundStyle(CatchTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(CatchSpacing.space4)

                        Text(CatchStrings.Onboarding.locationReassurance)
                            .font(.caption)
                            .foregroundStyle(CatchTheme.textSecondary.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .lineSpacing(CatchSpacing.space4)
                            .padding(.top, CatchSpacing.space4)
                    }

                    if !locationManager.hasRequested {
                        Button {
                            locationManager.requestPermission()
                        } label: {
                            HStack {
                                Image(systemName: "location.fill")
                                Text(CatchStrings.Onboarding.enableLocation)
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(CatchTheme.accessibleTextOrange)
                            .padding(.horizontal, CatchSpacing.space20)
                            .padding(.vertical, CatchSpacing.space10)
                            .background(CatchTheme.primary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .frame(minHeight: CatchTheme.minTapTarget)
                    } else {
                        HStack(spacing: CatchSpacing.space6) {
                            Image(systemName: locationManager.wasGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(locationManager.wasGranted ? .green : CatchTheme.textSecondary)
                            Text(locationManager.wasGranted ? CatchStrings.Onboarding.locationEnabled : CatchStrings.Onboarding.locationDenied)
                                .font(.caption)
                                .foregroundStyle(CatchTheme.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, CatchSpacing.space32)
                .frame(maxWidth: .infinity, minHeight: geo.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}

// MARK: - Location Manager for Onboarding

@Observable
class OnboardingLocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    var hasRequested = false
    var wasGranted = false

    override init() {
        super.init()
        manager.delegate = self
        // Check if already authorized
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            hasRequested = true
            wasGranted = true
        }
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status != .notDetermined {
            hasRequested = true
            wasGranted = status == .authorizedWhenInUse || status == .authorizedAlways
        }
    }
}
