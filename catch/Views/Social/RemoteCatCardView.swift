import SwiftUI

struct RemoteCatCardView: View {
    let cat: CloudCat
    let encounterCount: Int

    var body: some View {
        VStack(spacing: 8) {
            CatPhotoView(photoData: cat.photos.first, size: 120)
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusSmall))

            VStack(spacing: 4) {
                HStack {
                    Text(cat.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CatchTheme.textPrimary)
                        .lineLimit(1)
                    if cat.isOwned {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                            .foregroundStyle(CatchTheme.primary)
                    }
                }

                if !cat.breed.isEmpty {
                    Text(cat.breed.lowercased())
                        .font(.caption2)
                        .foregroundStyle(CatchTheme.primary)
                        .lineLimit(1)
                }

                Text("\(encounterCount) encounter\(encounterCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(CatchTheme.textSecondary)
            }
        }
        .padding(12)
        .background(CatchTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadius))
        .shadow(color: .black.opacity(CatchTheme.cardShadowOpacity), radius: CatchTheme.cardShadowRadius, y: CatchTheme.cardShadowY)
    }
}
