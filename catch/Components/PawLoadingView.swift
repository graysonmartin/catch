import SwiftUI
import CatchCore

struct PawLoadingView: View {
    enum Size {
        case full
        case inline

        var pawFont: Font {
            switch self {
            case .full: .title3
            case .inline: .caption
            }
        }

        var spacing: CGFloat {
            switch self {
            case .full: 10
            case .inline: 6
            }
        }
    }

    var size: Size = .full
    var label: String?

    @State private var animating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: CatchSpacing.space8) {
            HStack(spacing: size.spacing) {
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: "pawprint.fill")
                        .font(size.pawFont)
                        .foregroundStyle(CatchTheme.primary)
                        .scaleEffect(reduceMotion ? 1.0 : (animating ? 1.0 : 0.6))
                        .opacity(reduceMotion ? 1.0 : (animating ? 1.0 : 0.3))
                        .animation(
                            reduceMotion ? nil :
                                .easeInOut(duration: 0.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: animating
                        )
                }
            }

            if let label {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(CatchTheme.textSecondary)
            }
        }
        .frame(maxWidth: size == .full ? .infinity : nil,
               maxHeight: size == .full ? .infinity : nil)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label ?? CatchStrings.Accessibility.loading)
        .accessibilityAddTraits(.updatesFrequently)
        .onAppear { animating = true }
    }
}
