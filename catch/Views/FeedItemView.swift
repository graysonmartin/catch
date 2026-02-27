import SwiftUI
import CatchCore

private enum PillLayout {
    static let fontSize: CGFloat = 9
    static let horizontalPadding: CGFloat = 6
    static let verticalPadding: CGFloat = 2
    static let cornerRadius: CGFloat = 4
    static let activeBackgroundOpacity: Double = 0.15
    static let inactiveBackgroundOpacity: Double = 0.1
}

private enum FeedItemLayout {
    static let thumbnailSize: CGFloat = 48
    static let carouselHeight: CGFloat = 200
}

struct FeedItemView: View {
    let encounter: Encounter

    @State private var showComments = false

    private var isFirstEncounter: Bool {
        guard let cat = encounter.cat else { return false }
        guard let earliest = cat.encounters.min(by: { $0.date < $1.date }) else { return false }
        return earliest.id == encounter.id
    }

    private var isUnnamed: Bool {
        encounter.cat?.isUnnamed ?? false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CatchSpacing.space12) {
            // Header: photo + name + date
            HStack(spacing: CatchSpacing.space12) {
                CatPhotoView(photoData: encounter.cat?.photos.first, size: FeedItemLayout.thumbnailSize)

                VStack(alignment: .leading, spacing: CatchSpacing.space2) {
                    HStack(spacing: CatchSpacing.space4) {
                        Text(encounter.cat?.displayName ?? CatchStrings.Feed.unknownCat)
                            .font(.headline)
                            .foregroundStyle(isUnnamed ? CatchTheme.textSecondary : CatchTheme.textPrimary)
                        Text(isFirstEncounter ? CatchStrings.Feed.pillNew : CatchStrings.Feed.pillRepeat)
                            .font(.system(size: PillLayout.fontSize, weight: .bold))
                            .foregroundStyle(isFirstEncounter ? CatchTheme.primary : CatchTheme.textSecondary)
                            .padding(.horizontal, PillLayout.horizontalPadding)
                            .padding(.vertical, PillLayout.verticalPadding)
                            .background(
                                RoundedRectangle(cornerRadius: PillLayout.cornerRadius)
                                    .fill(isFirstEncounter ? CatchTheme.primary.opacity(PillLayout.activeBackgroundOpacity) : CatchTheme.textSecondary.opacity(PillLayout.inactiveBackgroundOpacity))
                            )
                        if isUnnamed {
                            Text(CatchStrings.Feed.pillStray)
                                .font(.system(size: PillLayout.fontSize, weight: .bold))
                                .foregroundStyle(CatchTheme.textSecondary)
                                .padding(.horizontal, PillLayout.horizontalPadding)
                                .padding(.vertical, PillLayout.verticalPadding)
                                .background(
                                    RoundedRectangle(cornerRadius: PillLayout.cornerRadius)
                                        .fill(CatchTheme.textSecondary.opacity(PillLayout.inactiveBackgroundOpacity))
                                )
                        }
                    }
                    Text(encounter.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(CatchTheme.textSecondary)
                }

                Spacer()

                if encounter.cat?.isOwned == true {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(CatchTheme.primary)
                        .font(.caption)
                }
            }

            // Photos — prefer encounter-specific photos, fall back to cat's photos
            if let photos = (!encounter.photos.isEmpty ? encounter.photos : encounter.cat?.photos),
               !photos.isEmpty {
                PhotoCarouselView(photos: photos, height: FeedItemLayout.carouselHeight, cornerRadius: CatchTheme.cornerRadiusSmall)
            }

            // Location
            if !encounter.location.name.isEmpty {
                Label(encounter.location.name, systemImage: "mappin.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(CatchTheme.textSecondary)
            }

            // Notes
            if !encounter.notes.isEmpty {
                Text(encounter.notes)
                    .font(.subheadline)
                    .foregroundStyle(CatchTheme.textPrimary)
            }

            // Interaction bar — only for synced encounters
            if let recordName = encounter.cloudKitRecordName {
                InteractionBar(encounterRecordName: recordName, showComments: $showComments)
            }
        }
        .padding()
        .background(CatchTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadius))
        .shadow(color: .black.opacity(CatchTheme.cardShadowOpacity), radius: CatchTheme.cardShadowRadius, y: CatchTheme.cardShadowY)
        .sheet(isPresented: $showComments) {
            if let recordName = encounter.cloudKitRecordName {
                CommentThreadView(encounterRecordName: recordName)
            }
        }
    }
}
