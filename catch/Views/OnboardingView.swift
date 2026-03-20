import SwiftUI
import CoreLocation
import CatchCore

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    @State private var locationManager = OnboardingLocationManager()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            CatchTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    tourPage.tag(1)
                    locationPage.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: currentPage)

                // Page dots + button
                VStack(spacing: CatchSpacing.space24) {
                    HStack(spacing: CatchSpacing.space8) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(index == currentPage ? CatchTheme.primary : CatchTheme.primary.opacity(0.25))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(CatchStrings.Accessibility.onboardingPage(currentPage + 1, of: 3))

                    Button {
                        if currentPage < 2 {
                            currentPage += 1
                        } else {
                            hasCompletedOnboarding = true
                        }
                    } label: {
                        Text(currentPage == 2 ? CatchStrings.Onboarding.letsGo : CatchStrings.Onboarding.next)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(CatchTheme.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    if currentPage < 2 {
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
        }
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

    // MARK: - Page 2: Tour

    private var tourPage: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: CatchSpacing.space32) {
                    Text(CatchStrings.Onboarding.tourTitle)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(CatchTheme.textPrimary)

                    VStack(alignment: .leading, spacing: CatchSpacing.space20) {
                        tourRow(
                            icon: "pawprint.fill",
                            title: CatchStrings.Onboarding.tourFeed,
                            detail: CatchStrings.Onboarding.tourFeedDetail
                        )
                        tourRow(
                            icon: "plus.circle.fill",
                            title: CatchStrings.Onboarding.tourLog,
                            detail: CatchStrings.Onboarding.tourLogDetail
                        )
                        tourRow(
                            icon: "map.fill",
                            title: CatchStrings.Onboarding.tourMap,
                            detail: CatchStrings.Onboarding.tourMapDetail
                        )
                        tourRow(
                            icon: "person.crop.circle",
                            title: CatchStrings.Onboarding.tourProfile,
                            detail: CatchStrings.Onboarding.tourProfileDetail
                        )
                    }
                    .padding(.horizontal, CatchSpacing.space8)
                }
                .padding(.horizontal, CatchSpacing.space32)
                .frame(maxWidth: .infinity, minHeight: geo.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    private func tourRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: CatchSpacing.space16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(CatchTheme.primary)
                .frame(width: 36, height: 36)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: CatchSpacing.space2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CatchTheme.textPrimary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(CatchTheme.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Page 3: Location Permission

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
