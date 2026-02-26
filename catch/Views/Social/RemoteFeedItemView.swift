import SwiftUI

private enum Layout {
    static let thumbnailSize: CGFloat = 48
    static let carouselHeight: CGFloat = 200
}

struct RemoteFeedItemView: View {
    let encounter: CloudEncounter
    let cat: CloudCat?

    var body: some View {
        VStack(alignment: .leading, spacing: CatchSpacing.space12) {
            header
            photos
            location
            notes
        }
        .padding()
        .background(CatchTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadius))
        .shadow(color: .black.opacity(CatchTheme.cardShadowOpacity), radius: CatchTheme.cardShadowRadius, y: CatchTheme.cardShadowY)
    }

    // MARK: - Subviews

    private var header: some View {
        HStack(spacing: CatchSpacing.space12) {
            CatPhotoView(photoData: cat?.photos.first, size: Layout.thumbnailSize)

            VStack(alignment: .leading, spacing: CatchSpacing.space2) {
                Text(cat?.displayName ?? CatchStrings.Social.unknownCat)
                    .font(.headline)
                    .foregroundStyle(CatchTheme.textPrimary)
                Text(encounter.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(CatchTheme.textSecondary)
            }

            Spacer()

            if cat?.isOwned == true {
                Image(systemName: "heart.fill")
                    .foregroundStyle(CatchTheme.primary)
                    .font(.caption)
            }
        }
    }

    @ViewBuilder
    private var photos: some View {
        let allPhotos = !encounter.photos.isEmpty ? encounter.photos : (cat?.photos ?? [])
        if !allPhotos.isEmpty {
            PhotoCarouselView(
                photos: allPhotos,
                height: Layout.carouselHeight,
                cornerRadius: CatchTheme.cornerRadiusSmall
            )
        }
    }

    @ViewBuilder
    private var location: some View {
        if !encounter.locationName.isEmpty {
            Label(encounter.locationName, systemImage: "mappin.circle.fill")
                .font(.subheadline)
                .foregroundStyle(CatchTheme.textSecondary)
        }
    }

    @ViewBuilder
    private var notes: some View {
        if !encounter.notes.isEmpty {
            Text(encounter.notes)
                .font(.subheadline)
                .foregroundStyle(CatchTheme.textPrimary)
        }
    }
}
