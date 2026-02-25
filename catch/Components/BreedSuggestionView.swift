import SwiftUI

struct BreedSuggestionView: View {
    let prediction: BreedPrediction?
    let isClassifying: Bool
    let onConfirm: (String) -> Void
    let onDismiss: () -> Void

    var body: some View {
        Group {
            if isClassifying {
                classifyingState
            } else if let prediction {
                suggestionState(prediction)
            }
        }
    }

    // MARK: - States

    private var classifyingState: some View {
        HStack(spacing: 8) {
            ProgressView()
                .tint(CatchTheme.primary)
            Text("analyzing this creature...")
                .font(.caption)
                .foregroundStyle(CatchTheme.textSecondary)
        }
        .padding(.vertical, 4)
    }

    private func suggestionState(_ prediction: BreedPrediction) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.caption)
                .foregroundStyle(CatchTheme.primary)

            if prediction.confidence >= 0.6 {
                Text("looks like a \(prediction.breed.lowercased())")
                    .font(.caption)
                    .foregroundStyle(CatchTheme.textPrimary)
            } else {
                Text("maybe a \(prediction.breed.lowercased())? honestly not sure")
                    .font(.caption)
                    .foregroundStyle(CatchTheme.textSecondary)
            }

            Spacer()

            Button {
                onConfirm(prediction.breed)
            } label: {
                Text("yep")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(CatchTheme.primary)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CatchTheme.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
