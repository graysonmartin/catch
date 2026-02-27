import SwiftUI
import CatchCore

struct RemoteDiaryEntryRow: View {
    let encounter: CloudEncounter
    let cat: CloudCat?
    let isFirstEncounter: Bool

    private enum Layout {
        static let thumbnailSize: CGFloat = 48
        static let pillFontSize: CGFloat = 9
        static let pillHPadding: CGFloat = 6
        static let pillVPadding: CGFloat = 2
        static let pillCornerRadius: CGFloat = 4
        static let activeOpacity: Double = 0.15
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

                    encounterPill

                    if cat?.isUnnamed == true {
                        strayPill
                    }

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

    // MARK: - Pills

    private var encounterPill: some View {
        Text(isFirstEncounter ? CatchStrings.Feed.pillNew : CatchStrings.Feed.pillRepeat)
            .font(.system(size: Layout.pillFontSize, weight: .bold))
            .foregroundStyle(isFirstEncounter ? CatchTheme.primary : CatchTheme.textSecondary)
            .padding(.horizontal, Layout.pillHPadding)
            .padding(.vertical, Layout.pillVPadding)
            .background(
                RoundedRectangle(cornerRadius: Layout.pillCornerRadius)
                    .fill(isFirstEncounter
                        ? CatchTheme.primary.opacity(Layout.activeOpacity)
                        : CatchTheme.textSecondary.opacity(Layout.inactiveOpacity))
            )
    }

    private var strayPill: some View {
        Text(CatchStrings.Feed.pillStray)
            .font(.system(size: Layout.pillFontSize, weight: .bold))
            .foregroundStyle(CatchTheme.textSecondary)
            .padding(.horizontal, Layout.pillHPadding)
            .padding(.vertical, Layout.pillVPadding)
            .background(
                RoundedRectangle(cornerRadius: Layout.pillCornerRadius)
                    .fill(CatchTheme.textSecondary.opacity(Layout.inactiveOpacity))
            )
    }

    // MARK: - Context

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
