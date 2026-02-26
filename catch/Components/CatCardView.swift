import SwiftUI

struct CatCardView: View {
    let data: CatDisplayData

    var body: some View {
        VStack(spacing: CatchSpacing.space8) {
            CatPhotoView(photoData: data.firstPhotoData, size: 120)
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusSmall))

            VStack(spacing: CatchSpacing.space4) {
                HStack {
                    Text(data.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(data.isUnnamed ? CatchTheme.textSecondary : CatchTheme.textPrimary)
                        .lineLimit(1)
                    if data.isSteven {
                        Image(systemName: "crown.fill")
                            .font(.caption2)
                            .foregroundStyle(CatchTheme.primary)
                    }
                    if data.isOwned {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                            .foregroundStyle(CatchTheme.primary)
                    }
                }

                Text(data.breed.isEmpty ? " " : data.breed.lowercased())
                    .font(.caption2)
                    .foregroundStyle(CatchTheme.primary)
                    .lineLimit(1)

                Text(CatchStrings.Common.encounterCount(data.encounterCount))
                    .font(.caption)
                    .foregroundStyle(CatchTheme.textSecondary)
            }
        }
        .padding(CatchSpacing.space12)
        .background(CatchTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadius))
        .shadow(color: .black.opacity(CatchTheme.cardShadowOpacity), radius: CatchTheme.cardShadowRadius, y: CatchTheme.cardShadowY)
    }
}
