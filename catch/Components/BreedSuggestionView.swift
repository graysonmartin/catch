import SwiftUI
import CatchCore

struct BreedSuggestionView: View {
    let prediction: BreedPrediction?
    let isClassifying: Bool
    var debugPredictions: [BreedPrediction] = []
    let onConfirm: (String) -> Void
    let onDismiss: () -> Void

    var body: some View {
        Group {
            if isClassifying {
                classifyingState
            } else if let prediction {
                suggestionState(prediction)
            }
            #if DEBUG
            if !debugPredictions.isEmpty {
                debugResultsView
            }
            #endif
        }
    }

    // MARK: - States

    private var classifyingState: some View {
        HStack(spacing: CatchSpacing.space8) {
            PawLoadingView(size: .inline)
            Text(CatchStrings.Components.analyzingCreature)
                .font(.caption)
                .foregroundStyle(CatchTheme.textSecondary)
        }
        .padding(.vertical, CatchSpacing.space4)
    }

    private func suggestionState(_ prediction: BreedPrediction) -> some View {
        HStack(spacing: CatchSpacing.space8) {
            Image(systemName: "sparkles")
                .font(.caption)
                .foregroundStyle(CatchTheme.primary)

            if prediction.confidence >= 0.6 {
                Text(CatchStrings.Components.looksLike(prediction.breed.lowercased()))
                    .font(.caption)
                    .foregroundStyle(CatchTheme.textPrimary)
            } else {
                Text(CatchStrings.Components.maybeLike(prediction.breed.lowercased()))
                    .font(.caption)
                    .foregroundStyle(CatchTheme.textSecondary)
            }

            Spacer()

            Button {
                onConfirm(prediction.breed)
            } label: {
                Text(CatchStrings.Components.yep)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, CatchSpacing.space10)
                    .padding(.vertical, CatchSpacing.space4)
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
        .padding(.vertical, CatchSpacing.space4)
    }

    // MARK: - Debug

    #if DEBUG
    private var debugResultsView: some View {
        VStack(alignment: .leading, spacing: CatchSpacing.space4) {
            Text("top predictions")
                .font(.caption2.weight(.semibold).monospaced())
                .foregroundStyle(CatchTheme.textSecondary)
            ForEach(debugPredictions, id: \.rawIdentifier) { p in
                HStack {
                    Text(p.breed)
                        .font(.caption.monospaced())
                    Spacer()
                    Text(String(format: "%.1f%%", p.confidence * 100))
                        .font(.caption.weight(.medium).monospaced())
                        .foregroundStyle(p.confidence >= 0.5 ? CatchTheme.primary : CatchTheme.textSecondary)
                }
            }
        }
        .padding(CatchSpacing.space8)
        .background(CatchTheme.background.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    #endif
}
