import SwiftUI
import CoreLocation

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    @State private var locationManager = OnboardingLocationManager()

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
                .animation(.easeInOut(duration: 0.3), value: currentPage)

                // Page dots + button
                VStack(spacing: 24) {
                    HStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(index == currentPage ? CatchTheme.primary : CatchTheme.primary.opacity(0.25))
                                .frame(width: 8, height: 8)
                        }
                    }

                    Button {
                        if currentPage < 2 {
                            currentPage += 1
                        } else {
                            hasCompletedOnboarding = true
                        }
                    } label: {
                        Text(currentPage == 2 ? "let's go" : "next")
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
                            Text("skip")
                                .font(.subheadline)
                                .foregroundStyle(CatchTheme.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "pawprint.fill")
                .font(.system(size: 72))
                .foregroundStyle(CatchTheme.primary)

            VStack(spacing: 12) {
                Text("catch")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(CatchTheme.textPrimary)

                Text("track every cat you meet.")
                    .font(.title3)
                    .foregroundStyle(CatchTheme.textSecondary)

                Text("log sightings. remember names.\nbecome the neighborhood cat census.")
                    .font(.subheadline)
                    .foregroundStyle(CatchTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Page 2: Tour

    private var tourPage: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("here's the rundown")
                .font(.title2.weight(.bold))
                .foregroundStyle(CatchTheme.textPrimary)

            VStack(alignment: .leading, spacing: 20) {
                tourRow(
                    icon: "pawprint.fill",
                    title: "feed",
                    detail: "your timeline of every cat encounter"
                )
                tourRow(
                    icon: "plus.circle.fill",
                    title: "log",
                    detail: "register new cats or log re-sightings"
                )
                tourRow(
                    icon: "map.fill",
                    title: "map",
                    detail: "see where all your cats hang out"
                )
                tourRow(
                    icon: "square.grid.2x2.fill",
                    title: "collection",
                    detail: "your personal cat index"
                )
            }
            .padding(.horizontal, 8)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private func tourRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(CatchTheme.primary)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CatchTheme.textPrimary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(CatchTheme.textSecondary)
            }
        }
    }

    // MARK: - Page 3: Location Permission

    private var locationPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "location.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(CatchTheme.primary)

            VStack(spacing: 12) {
                Text("one more thing")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(CatchTheme.textPrimary)

                Text("catch uses your location to pin\nwhere you spot cats on the map.")
                    .font(.subheadline)
                    .foregroundStyle(CatchTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Text("you can always skip this per-encounter.\nwe're not tracking you, promise.")
                    .font(.caption)
                    .foregroundStyle(CatchTheme.textSecondary.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.top, 4)
            }

            if !locationManager.hasRequested {
                Button {
                    locationManager.requestPermission()
                } label: {
                    HStack {
                        Image(systemName: "location.fill")
                        Text("enable location")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(CatchTheme.primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(CatchTheme.primary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: locationManager.wasGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(locationManager.wasGranted ? .green : CatchTheme.textSecondary)
                    Text(locationManager.wasGranted ? "location enabled" : "no worries, you can change this in settings")
                        .font(.caption)
                        .foregroundStyle(CatchTheme.textSecondary)
                }
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
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
