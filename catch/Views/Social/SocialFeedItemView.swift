import SwiftUI
import CatchCore

private enum Layout {
    static let thumbnailSize: CGFloat = 48
    static let carouselHeight: CGFloat = 200
    static let pillFontSize: CGFloat = 9
    static let pillHPadding: CGFloat = 6
    static let pillVPadding: CGFloat = 2
    static let pillCornerRadius: CGFloat = 4
    static let pillActiveBackgroundOpacity: Double = 0.15
    static let pillInactiveBackgroundOpacity: Double = 0.1
}

struct SocialFeedItemView: View {
    let encounter: CloudEncounter
    let cat: CloudCat?
    let owner: CloudUserProfile
    let isFirstEncounter: Bool
    var onTapCatPhoto: (() -> Void)?

    @State private var showComments = false

    private var isUnnamed: Bool {
        cat?.isUnnamed ?? true
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CatchSpacing.space12) {
            catHeader
            photos
            location
            notes
            InteractionBar(
                encounterRecordName: encounter.recordName,
                showComments: $showComments,
                ownerRoute: RemoteProfileRoute(userID: owner.appleUserID, displayName: owner.displayName)
            )
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

    private var catHeader: some View {
        HStack(spacing: CatchSpacing.space12) {
            Button {
                onTapCatPhoto?()
            } label: {
                CatPhotoView(photoData: cat?.photos.first, size: Layout.thumbnailSize)
            }
            .buttonStyle(.plain)
            .disabled(onTapCatPhoto == nil)

            VStack(alignment: .leading, spacing: CatchSpacing.space2) {
                HStack(spacing: CatchSpacing.space4) {
                    Text(cat?.displayName ?? CatchStrings.Social.unknownCat)
                        .font(.headline)
                        .foregroundStyle(isUnnamed ? CatchTheme.textSecondary : CatchTheme.textPrimary)
                    pill(
                        text: isFirstEncounter ? CatchStrings.Feed.pillNew : CatchStrings.Feed.pillRepeat,
                        isActive: isFirstEncounter
                    )
                    if isUnnamed {
                        pill(text: CatchStrings.Feed.pillStray, isActive: false)
                    }
                }
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

    private func pill(text: String, isActive: Bool) -> some View {
        Text(text)
            .font(.system(size: Layout.pillFontSize, weight: .bold))
            .foregroundStyle(isActive ? CatchTheme.primary : CatchTheme.textSecondary)
            .padding(.horizontal, Layout.pillHPadding)
            .padding(.vertical, Layout.pillVPadding)
            .background(
                RoundedRectangle(cornerRadius: Layout.pillCornerRadius)
                    .fill(
                        isActive
                            ? CatchTheme.primary.opacity(Layout.pillActiveBackgroundOpacity)
                            : CatchTheme.textSecondary.opacity(Layout.pillInactiveBackgroundOpacity)
                    )
            )
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
