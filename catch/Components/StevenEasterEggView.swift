import SwiftUI

struct StevenEasterEggView: View {
    var onComplete: () -> Void

    @State private var isShowingPaws = false
    @State private var isShowingToast = false

    private let pawCount = 25

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            ForEach(0..<pawCount, id: \.self) { index in
                PawParticle(index: index, isAnimating: isShowingPaws)
            }

            toastView
        }
        .onAppear {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.easeOut(duration: 0.6)) {
                isShowingPaws = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                isShowingToast = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                onComplete()
            }
        }
    }

    private var toastView: some View {
        Text(CatchStrings.Components.youFoundHim)
            .font(.title2.weight(.bold))
            .foregroundStyle(CatchTheme.textPrimary)
            .padding(.horizontal, CatchSpacing.space24)
            .padding(.vertical, CatchSpacing.space14)
            .background(
                RoundedRectangle(cornerRadius: CatchTheme.cornerRadius)
                    .fill(CatchTheme.cardBackground)
                    .shadow(color: CatchTheme.primary.opacity(0.4), radius: 20)
            )
            .scaleEffect(isShowingToast ? 1 : 0.8)
            .opacity(isShowingToast ? 1 : 0)
    }
}

// MARK: - PawParticle

private struct PawParticle: View {
    let index: Int
    let isAnimating: Bool

    @State private var randomX: CGFloat = .random(in: -0.45...0.45)
    @State private var randomDelay: Double = .random(in: 0...0.8)
    @State private var randomRotation: Double = .random(in: -40...40)
    @State private var randomSize: CGFloat = .random(in: 14...26)

    private var color: Color {
        [CatchTheme.primary, CatchTheme.secondary, CatchTheme.primary.opacity(0.7)][index % 3]
    }

    var body: some View {
        GeometryReader { geo in
            Image(systemName: "pawprint.fill")
                .font(.system(size: randomSize))
                .foregroundStyle(color)
                .rotationEffect(.degrees(randomRotation))
                .position(
                    x: geo.size.width * (0.5 + randomX),
                    y: isAnimating ? geo.size.height + 40 : -40
                )
                .animation(
                    .easeIn(duration: .random(in: 1.8...2.8))
                    .delay(randomDelay),
                    value: isAnimating
                )
        }
        .allowsHitTesting(false)
    }
}
