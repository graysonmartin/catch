import SwiftUI
import CatchCore

struct BreedPredictionCard: View {
    let predictions: [BreedPrediction]
    let isClassifying: Bool
    let onSelect: (String) -> Void
    let onDismiss: () -> Void

    var body: some View {
        Group {
            if isClassifying {
                classifyingState
            } else if !predictions.isEmpty {
                predictionsCard
            }
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

    private var predictionsCard: some View {
        VStack(alignment: .leading, spacing: CatchSpacing.space10) {
            HStack(spacing: CatchSpacing.space6) {
                Image(systemName: "sparkles")
                    .font(.subheadline)
                    .foregroundStyle(CatchTheme.primary)
                Text(CatchStrings.Components.weThinkThisIs)
                    .font(.subheadline)
                    .foregroundStyle(CatchTheme.textSecondary)
            }

            VStack(spacing: CatchSpacing.space6) {
                ForEach(Array(predictions.enumerated()), id: \.element.rawIdentifier) { index, prediction in
                    BreedPredictionRow(
                        prediction: prediction,
                        isTopPrediction: index == 0,
                        onSelect: onSelect
                    )
                }
            }

            Button {
                onDismiss()
            } label: {
                Text(CatchStrings.Components.noneOfThese)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(CatchTheme.textSecondary)
                    .padding(.horizontal, CatchSpacing.space10)
                    .padding(.vertical, CatchSpacing.space6)
                    .background(CatchTheme.background)
                    .clipShape(Capsule())
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .buttonStyle(.plain)
        }
        .padding(CatchSpacing.space12)
        .background(CatchTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusSmall))
        .shadow(
            color: .black.opacity(CatchTheme.cardShadowOpacity),
            radius: CatchTheme.cardShadowRadius,
            y: CatchTheme.cardShadowY
        )
    }
}

// MARK: - BreedPredictionRow

private struct BreedPredictionRow: View {
    let prediction: BreedPrediction
    let isTopPrediction: Bool
    let onSelect: (String) -> Void

    var body: some View {
        Button {
            onSelect(prediction.breed)
        } label: {
            HStack(spacing: CatchSpacing.space6) {
                Text(prediction.breed)
                    .font(.subheadline.weight(isTopPrediction ? .semibold : .regular))
                    .foregroundStyle(CatchTheme.textPrimary)
                Spacer()
                Text(confidenceText)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(CatchTheme.textSecondary)
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CatchTheme.primary.opacity(isTopPrediction ? 1 : 0.5))
            }
            .padding(.horizontal, CatchSpacing.space10)
            .padding(.vertical, CatchSpacing.space8)
            .background {
                GeometryReader { geo in
                    CatchTheme.primary
                        .opacity(isTopPrediction ? 0.15 : 0.08)
                        .frame(width: geo.size.width * CGFloat(prediction.confidence))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusTight))
            .overlay(
                RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusTight)
                    .strokeBorder(CatchTheme.primary.opacity(isTopPrediction ? 0.3 : 0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var confidenceText: String {
        let pct = Int(round(prediction.confidence * 100))
        return "\(pct)%"
    }
}
