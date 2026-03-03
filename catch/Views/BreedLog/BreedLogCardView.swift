import SwiftUI
import CatchCore

struct BreedLogCardView: View {
    let entry: BreedLogEntry

    var body: some View {
        VStack(spacing: CatchSpacing.space6) {
            photoOrSilhouette
                .frame(width: 70, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusSmall))

            if entry.isDiscovered {
                Text(entry.catalogEntry.displayName.lowercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CatchTheme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 28)
            } else {
                Text(CatchStrings.BreedLog.undiscoveredPlaceholder)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CatchTheme.textSecondary.opacity(0.5))
                    .frame(height: 28)
            }

            BreedRarityBadge(rarity: entry.catalogEntry.rarity)
        }
        .padding(CatchSpacing.space8)
        .frame(maxWidth: .infinity)
        .background(entry.isDiscovered ? CatchTheme.cardBackground : CatchTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusSmall))
        .shadow(
            color: entry.isDiscovered ? .black.opacity(CatchTheme.cardShadowOpacity) : .clear,
            radius: CatchTheme.cardShadowRadius,
            y: CatchTheme.cardShadowY
        )
        .opacity(entry.isDiscovered ? 1.0 : 0.5)
    }

    @ViewBuilder
    private var photoOrSilhouette: some View {
        if let data = entry.previewPhotoData,
           let uiImage = ImageDownsampler.shared.downsample(data: data, to: CGSize(width: 70, height: 70)) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else if entry.isDiscovered {
            Image(systemName: entry.catalogEntry.icon)
                .font(.title2)
                .foregroundStyle(CatchTheme.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(CatchTheme.secondary.opacity(0.3))
        } else {
            Image(systemName: "questionmark")
                .font(.title2)
                .foregroundStyle(CatchTheme.textSecondary.opacity(0.3))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(CatchTheme.textSecondary.opacity(0.08))
        }
    }
}
