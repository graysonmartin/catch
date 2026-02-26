import SwiftUI

struct BreedLogProgressView: View {
    let discoveredCount: Int
    let totalCount: Int

    private var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(discoveredCount) / Double(totalCount)
    }

    private var flavorText: String {
        switch discoveredCount {
        case 0:
            return CatchStrings.BreedLog.flavorZero
        case 1...3:
            return CatchStrings.BreedLog.flavorLow
        case 4...8:
            return CatchStrings.BreedLog.flavorMedLow
        case 9...15:
            return CatchStrings.BreedLog.flavorMedium
        case 16...22:
            return CatchStrings.BreedLog.flavorMedHigh
        case 23...26:
            return CatchStrings.BreedLog.flavorHigh
        case 27:
            return CatchStrings.BreedLog.flavorMax
        default:
            return CatchStrings.BreedLog.flavorDefault
        }
    }

    var body: some View {
        VStack(spacing: CatchSpacing.space8) {
            HStack {
                Text("\(discoveredCount) / \(totalCount)")
                    .font(.title2.weight(.bold).monospacedDigit())
                    .foregroundStyle(CatchTheme.textPrimary)

                Text(CatchStrings.BreedLog.breedsDiscovered)
                    .font(.subheadline)
                    .foregroundStyle(CatchTheme.textSecondary)

                Spacer()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(CatchTheme.textSecondary.opacity(0.15))
                        .frame(height: 10)

                    Capsule()
                        .fill(CatchTheme.primary)
                        .frame(width: geo.size.width * progress, height: 10)
                        .animation(.spring(response: 0.5), value: progress)
                }
            }
            .frame(height: 10)

            Text(flavorText)
                .font(.caption)
                .foregroundStyle(CatchTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(CatchTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadius))
        .shadow(color: .black.opacity(CatchTheme.cardShadowOpacity), radius: CatchTheme.cardShadowRadius, y: CatchTheme.cardShadowY)
    }
}
