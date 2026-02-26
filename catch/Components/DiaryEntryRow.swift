import SwiftUI

private enum DiaryRowLayout {
    static let thumbnailSize: CGFloat = 48
    static let pillFontSize: CGFloat = 9
    static let pillHPadding: CGFloat = 6
    static let pillVPadding: CGFloat = 2
    static let pillCornerRadius: CGFloat = 4
    static let activeOpacity: Double = 0.15
    static let inactiveOpacity: Double = 0.1
}

struct DiaryEntryRow: View {
    let encounter: Encounter
    let isFirstEncounter: Bool

    private var cat: Cat? { encounter.cat }

    private var isUnnamed: Bool {
        cat?.isUnnamed ?? false
    }

    var body: some View {
        HStack(alignment: .top, spacing: CatchSpacing.space12) {
            CatPhotoView(photoData: cat?.photos.first, size: DiaryRowLayout.thumbnailSize)

            VStack(alignment: .leading, spacing: CatchSpacing.space2) {
                HStack(spacing: CatchSpacing.space4) {
                    Text(cat?.displayName ?? CatchStrings.Feed.unknownCat)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isUnnamed ? CatchTheme.textSecondary : CatchTheme.textPrimary)
                        .lineLimit(1)

                    encounterPill

                    if isUnnamed {
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
            .font(.system(size: DiaryRowLayout.pillFontSize, weight: .bold))
            .foregroundStyle(isFirstEncounter ? CatchTheme.primary : CatchTheme.textSecondary)
            .padding(.horizontal, DiaryRowLayout.pillHPadding)
            .padding(.vertical, DiaryRowLayout.pillVPadding)
            .background(
                RoundedRectangle(cornerRadius: DiaryRowLayout.pillCornerRadius)
                    .fill(isFirstEncounter
                        ? CatchTheme.primary.opacity(DiaryRowLayout.activeOpacity)
                        : CatchTheme.textSecondary.opacity(DiaryRowLayout.inactiveOpacity))
            )
    }

    private var strayPill: some View {
        Text(CatchStrings.Feed.pillStray)
            .font(.system(size: DiaryRowLayout.pillFontSize, weight: .bold))
            .foregroundStyle(CatchTheme.textSecondary)
            .padding(.horizontal, DiaryRowLayout.pillHPadding)
            .padding(.vertical, DiaryRowLayout.pillVPadding)
            .background(
                RoundedRectangle(cornerRadius: DiaryRowLayout.pillCornerRadius)
                    .fill(CatchTheme.textSecondary.opacity(DiaryRowLayout.inactiveOpacity))
            )
    }

    // MARK: - Context

    @ViewBuilder
    private var contextLine: some View {
        if !encounter.location.name.isEmpty {
            Label(encounter.location.name, systemImage: "mappin")
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
