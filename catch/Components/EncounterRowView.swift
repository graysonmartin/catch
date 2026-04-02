import SwiftUI
import CatchCore

struct EncounterRowView: View {
    let encounter: Encounter
    private let thumbnailSize: CGFloat = 48

    var body: some View {
        HStack(spacing: CatchSpacing.space12) {
            encounterThumbnail

            VStack(alignment: .leading, spacing: CatchSpacing.space2) {
                Text(DateFormatting.encounterDateTime(encounter.date))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(CatchTheme.textPrimary)
                if !encounter.location.name.isEmpty {
                    Label(encounter.location.name, systemImage: "mappin")
                        .font(.caption)
                        .foregroundStyle(CatchTheme.textSecondary)
                }
                if !encounter.notes.isEmpty {
                    Text(encounter.notes)
                        .font(.caption)
                        .foregroundStyle(CatchTheme.textSecondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CatchTheme.textSecondary.opacity(0.4))
                .accessibilityHidden(true)
        }
        .padding(CatchSpacing.space12)
        .background(CatchTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusTight))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .shadow(
            color: .black.opacity(CatchTheme.cardShadowOpacity),
            radius: CatchTheme.cardShadowRadius,
            y: CatchTheme.cardShadowY
        )
    }

    // MARK: - Thumbnail

    @ViewBuilder
    private var encounterThumbnail: some View {
        if let firstUrl = encounter.photoUrls.first {
            RemoteImageView(urlString: ThumbnailURL.thumbnailOrOriginal(for: firstUrl)) {
                thumbnailPlaceholder
            }
            .frame(width: thumbnailSize, height: thumbnailSize)
            .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusTight))
        } else {
            thumbnailPlaceholder
        }
    }

    private var thumbnailPlaceholder: some View {
        Image(systemName: "camera.fill")
            .font(.system(size: 16))
            .foregroundStyle(CatchTheme.primary.opacity(0.6))
            .frame(width: thumbnailSize, height: thumbnailSize)
            .background(CatchTheme.secondary.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusTight))
    }
}
