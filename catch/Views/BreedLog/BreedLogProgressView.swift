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
            return "steven is judging you"
        case 1...3:
            return "barely scratching the surface"
        case 4...8:
            return "you're getting out more. proud of you"
        case 9...15:
            return "okay cat whisperer, we see you"
        case 16...22:
            return "this is becoming a whole thing huh"
        case 23...26:
            return "so close. don't sleep now"
        case 27:
            return "touch grass maybe?"
        default:
            return "how did you even get here"
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(discoveredCount) / \(totalCount)")
                    .font(.title2.weight(.bold).monospacedDigit())
                    .foregroundStyle(CatchTheme.textPrimary)

                Text("breeds discovered")
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
