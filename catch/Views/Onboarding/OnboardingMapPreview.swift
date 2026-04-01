import SwiftUI
import MapKit
import CatchCore

/// Onboarding preview page showing the cat map feature.
/// Displays a real MapKit map centered on the US with mock cat pins.
struct OnboardingMapPreview: View {

    private let mockPins: [MockCatPin] = [
        MockCatPin(id: "pin_a", name: CatchStrings.OnboardingTour.mapMockCatA, image: "OnboardingSteven", coordinate: .init(latitude: 39.5, longitude: -98.0), isOwn: true),
        MockCatPin(id: "pin_b", name: CatchStrings.OnboardingTour.mapMockCatB, image: "OnboardingGarfield", coordinate: .init(latitude: 37.0, longitude: -95.0), isOwn: false),
        MockCatPin(id: "pin_c", name: CatchStrings.OnboardingTour.mapMockCatC, image: "OnboardingOdie", coordinate: .init(latitude: 41.0, longitude: -101.0), isOwn: false)
    ]

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: CatchSpacing.space24) {
                    headerSection
                    mapCard
                    legendRow
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
            Image(systemName: "map.fill")
                .font(.system(size: 48))
                .foregroundStyle(CatchTheme.primary)
                .accessibilityHidden(true)

            Text(CatchStrings.OnboardingTour.mapTitle)
                .font(.title2.weight(.bold))
                .foregroundStyle(CatchTheme.textPrimary)
                .multilineTextAlignment(.center)

            Text(CatchStrings.OnboardingTour.mapSubtitle)
                .font(.subheadline)
                .foregroundStyle(CatchTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(CatchSpacing.space4)
        }
    }

    // MARK: - Map

    private var mapCard: some View {
        Map(interactionModes: []) {
            ForEach(mockPins) { pin in
                Annotation(pin.name, coordinate: pin.coordinate) {
                    pinMarker(image: pin.image, name: pin.name, isOwn: pin.isOwn)
                }
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadius))
        .shadow(
            color: .black.opacity(CatchTheme.cardShadowOpacity),
            radius: CatchTheme.cardShadowRadius,
            y: CatchTheme.cardShadowY
        )
        .allowsHitTesting(false)
    }

    private func pinMarker(image: String, name: String, isOwn: Bool) -> some View {
        let pinColor = isOwn ? CatchTheme.primary : CatchTheme.remotePinColor

        return VStack(spacing: CatchSpacing.space2) {
            Image(image)
                .resizable()
                .scaledToFill()
                .frame(width: 28, height: 28)
                .clipShape(Circle())
                .overlay(Circle().stroke(pinColor, lineWidth: 2))
                .shadow(color: .black.opacity(0.15), radius: 3, y: 2)

            Text(name)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(CatchTheme.textPrimary)
                .padding(.horizontal, CatchSpacing.space4)
                .padding(.vertical, 1)
                .background(
                    Capsule()
                        .fill(CatchTheme.cardBackground.opacity(0.9))
                )
        }
    }

    // MARK: - Legend

    private var legendRow: some View {
        HStack(spacing: CatchSpacing.space16) {
            legendItem(color: CatchTheme.primary, label: CatchStrings.OnboardingTour.mapLegendYours)
            legendItem(color: CatchTheme.remotePinColor, label: CatchStrings.OnboardingTour.mapLegendFriends)
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: CatchSpacing.space6) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(.caption)
                .foregroundStyle(CatchTheme.textSecondary)
        }
    }
}

// MARK: - Mock Data

private struct MockCatPin: Identifiable {
    let id: String
    let name: String
    let image: String
    let coordinate: CLLocationCoordinate2D
    let isOwn: Bool
}
