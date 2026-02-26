import SwiftUI

private enum Layout {
    static let thumbnailSize: CGFloat = 48
    static let carouselHeight: CGFloat = 200
    static let ownerIconSize: CGFloat = 9
    static let pillFontSize: CGFloat = 9
    static let pillHPadding: CGFloat = 6
    static let pillVPadding: CGFloat = 2
    static let pillCornerRadius: CGFloat = 4
    static let pillBackgroundOpacity: Double = 0.15
}

struct SocialFeedItemView: View {
    let encounter: CloudEncounter
    let cat: CloudCat?
    let owner: CloudUserProfile

    @State private var showComments = false
    @State private var isShowingOwnerProfile = false

    var body: some View {
        VStack(alignment: .leading, spacing: CatchSpacing.space12) {
            ownerHeader
            catHeader
            photos
            location
            notes
            InteractionBar(encounterRecordName: encounter.recordName, showComments: $showComments)
        }
        .padding()
        .background(CatchTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadius))
        .shadow(color: .black.opacity(CatchTheme.cardShadowOpacity), radius: CatchTheme.cardShadowRadius, y: CatchTheme.cardShadowY)
        .sheet(isPresented: $showComments) {
            CommentThreadView(encounterRecordName: encounter.recordName)
        }
    }

    // MARK: - Subviews

    private var ownerHeader: some View {
        Button {
            isShowingOwnerProfile = true
        } label: {
            HStack(spacing: CatchSpacing.space4) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: Layout.ownerIconSize))
                    .foregroundStyle(CatchTheme.textSecondary)
                Text(CatchStrings.Feed.spottedBy(owner.displayName))
                    .font(.caption)
                    .foregroundStyle(CatchTheme.textSecondary)
                friendPill
                Spacer()
            }
        }
        .buttonStyle(.plain)
        .navigationDestination(isPresented: $isShowingOwnerProfile) {
            RemoteProfileContent(
                userID: owner.appleUserID,
                initialDisplayName: owner.displayName
            )
        }
    }

    private var friendPill: some View {
        Text(CatchStrings.Feed.pillFriend)
            .font(.system(size: Layout.pillFontSize, weight: .bold))
            .foregroundStyle(CatchTheme.primary)
            .padding(.horizontal, Layout.pillHPadding)
            .padding(.vertical, Layout.pillVPadding)
            .background(
                RoundedRectangle(cornerRadius: Layout.pillCornerRadius)
                    .fill(CatchTheme.primary.opacity(Layout.pillBackgroundOpacity))
            )
    }

    private var catHeader: some View {
        HStack(spacing: CatchSpacing.space12) {
            CatPhotoView(photoData: cat?.photos.first, size: Layout.thumbnailSize)

            VStack(alignment: .leading, spacing: CatchSpacing.space2) {
                Text(cat?.displayName ?? CatchStrings.Social.unknownCat)
                    .font(.headline)
                    .foregroundStyle(cat?.isUnnamed == true ? CatchTheme.textSecondary : CatchTheme.textPrimary)
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
