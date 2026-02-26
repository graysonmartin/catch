import SwiftUI

struct RemoteDiaryEntryRow: View {
    let encounter: CloudEncounter
    let cat: CloudCat?

    private enum Layout {
        static let thumbnailSize: CGFloat = 48
        static let pillFontSize: CGFloat = 9
        static let pillHPadding: CGFloat = 6
        static let pillVPadding: CGFloat = 2
        static let pillCornerRadius: CGFloat = 4
        static let inactiveOpacity: Double = 0.1
    }

    var body: some View {
        HStack(alignment: .top, spacing: CatchSpacing.space12) {
            CatPhotoView(photoData: cat?.photos.first, size: Layout.thumbnailSize)

            VStack(alignment: .leading, spacing: CatchSpacing.space2) {
                HStack(spacing: CatchSpacing.space4) {
                    Text(cat?.displayName ?? CatchStrings.Social.unknownCat)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(cat?.isUnnamed == true ? CatchTheme.textSecondary : CatchTheme.textPrimary)
                        .lineLimit(1)

                    if cat?.isOwned == true {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(CatchTheme.primary)
                            .font(.system(size: 10))
                    }

                    Spacer()

                    Text(encounter.date.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(CatchTheme.textSecondary)
                }

                contextLine
            }
        }
        .padding(.vertical, CatchSpacing.space4)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var contextLine: some View {
        if !encounter.locationName.isEmpty {
            Label(encounter.locationName, systemImage: "mappin")
                .font(.caption)
                .foregroundStyle(CatchTheme.textSecondary)
                .lineLimit(1)
        } else if !encounter.notes.isEmpty {
            Text(encounter.notes)
                .font(.caption)
                .foregroundStyle(CatchTheme.textSecondary)
                .lineLimit(1)
        }
    }
}
