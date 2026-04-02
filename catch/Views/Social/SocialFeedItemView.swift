import SwiftUI
import CatchCore

struct SocialFeedItemView: View {
    let encounter: CloudEncounter
    let cat: CloudCat?
    let owner: CloudUserProfile
    let isFirstEncounter: Bool
    let catEncounters: [CloudEncounter]

    @Environment(ToastManager.self) private var toastManager

    @State private var showDetail = false
    @State private var showReportSheet = false

    private var isUnnamed: Bool {
        cat?.isUnnamed ?? true
    }

    private var detailData: EncounterDetailData {
        EncounterDetailData(remote: encounter, cat: cat, isFirstEncounter: isFirstEncounter, owner: owner)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CatchSpacing.space12) {
            catHeader
            photos
            encounterMetadata
            InteractionBar(
                encounterRecordName: encounter.recordName,
                showDetail: $showDetail,
                ownerRoute: RemoteProfileRoute(userID: owner.appleUserID, displayName: owner.displayName),
                ownerHandle: owner.username.map { "@\($0)" },
                encounterDate: encounter.date
            )
        }
        .padding()
        .background(CatchTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadius))
        .shadow(color: .black.opacity(CatchTheme.cardShadowOpacity), radius: CatchTheme.cardShadowRadius, y: CatchTheme.cardShadowY)
        .contentShape(Rectangle())
        .onTapGesture { showDetail = true }
        .accessibilityElement(children: .contain)
        .accessibilityHint(CatchStrings.Accessibility.feedCardHint)
        .sheet(isPresented: $showDetail) {
            EncounterDetailSheet(data: detailData, isOwnEncounter: false)
        }
        .sheet(isPresented: $showReportSheet) {
            ReportEncounterView(encounterRecordName: encounter.recordName)
        }
    }

    // MARK: - Subviews

    private var catHeader: some View {
        HStack(spacing: CatchSpacing.space12) {
            catPhotoLink

            VStack(alignment: .leading, spacing: CatchSpacing.space2) {
                Text(cat?.displayName ?? CatchStrings.Social.unknownCat)
                    .font(.headline)
                    .foregroundStyle(isUnnamed ? CatchTheme.textSecondary : CatchTheme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: CatchSpacing.space4) {
                    pill(
                        text: isFirstEncounter ? CatchStrings.Feed.pillNew : CatchStrings.Feed.pillRepeat,
                        isActive: isFirstEncounter
                    )
                    if isUnnamed {
                        pill(text: CatchStrings.Feed.pillStray, isActive: false)
                    }
                }
            }

            Spacer()

            if cat?.isOwned == true {
                Image(systemName: "heart.fill")
                    .foregroundStyle(CatchTheme.primary)
                    .font(.caption)
                    .accessibilityLabel(CatchStrings.Accessibility.ownedCat)
            }

            reportMenu
        }
    }

    private var reportMenu: some View {
        Menu {
            Button {
                showReportSheet = true
            } label: {
                Label(CatchStrings.Report.reportPost, systemImage: "flag")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.body)
                .foregroundStyle(CatchTheme.textSecondary)
                .frame(minWidth: CatchTheme.minTapTarget, minHeight: CatchTheme.minTapTarget)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(CatchStrings.Accessibility.moreOptions)
    }

    @ViewBuilder
    private var catPhotoLink: some View {
        if let cat {
            NavigationLink {
                RemoteCatProfileView(
                    cat: cat,
                    encounters: catEncounters,
                    owner: owner
                )
            } label: {
                CatPhotoView(
                    photoData: cat.photos.first,
                    photoUrl: cat.photoUrls.first,
                    size: FeedCardLayout.thumbnailSize,
                    accessibilityName: cat.displayName
                )
            }
            .buttonStyle(.plain)
        } else {
            CatPhotoView(photoData: nil, size: FeedCardLayout.thumbnailSize)
        }
    }

    private func pill(text: String, isActive: Bool) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(isActive ? CatchTheme.accessibleTextOrange : CatchTheme.textSecondary)
            .padding(.horizontal, FeedCardLayout.pillHorizontalPadding)
            .padding(.vertical, FeedCardLayout.pillVerticalPadding)
            .background(
                RoundedRectangle(cornerRadius: FeedCardLayout.pillCornerRadius)
                    .fill(
                        isActive
                            ? CatchTheme.primary.opacity(FeedCardLayout.pillActiveBackgroundOpacity)
                            : CatchTheme.textSecondary.opacity(FeedCardLayout.pillInactiveBackgroundOpacity)
                    )
            )
            .fixedSize()
            .accessibilityLabel(CatchStrings.Accessibility.encounterPill(text))
    }

    // MARK: - Photos

    @ViewBuilder
    private var photos: some View {
        let allPhotos = !encounter.photos.isEmpty ? encounter.photos : (cat?.photos ?? [])
        let allPhotoUrls = !encounter.photoUrls.isEmpty ? encounter.photoUrls : (cat?.photoUrls ?? [])
        if !allPhotos.isEmpty || !allPhotoUrls.isEmpty {
            PhotoCarouselView(
                photos: allPhotos,
                photoUrls: allPhotoUrls,
                height: FeedCardLayout.carouselHeight,
                cornerRadius: CatchTheme.cornerRadiusSmall,
                onTap: { showDetail = true }
            )
        }
    }

    // MARK: - Encounter Metadata

    private var encounterMetadata: some View {
        VStack(alignment: .leading, spacing: CatchSpacing.space4) {
            breed
            location
            notes
        }
    }

    @ViewBuilder
    private var breed: some View {
        if let breedName = cat?.breed, !breedName.isEmpty {
            HStack(spacing: CatchSpacing.space6) {
                Image(systemName: "pawprint.fill")
                    .frame(width: 16, alignment: .center)
                    .accessibilityHidden(true)
                Text(breedName)
            }
            .font(.subheadline)
            .foregroundStyle(CatchTheme.textSecondary)
        }
    }

    @ViewBuilder
    private var location: some View {
        if !encounter.locationName.isEmpty {
            HStack(spacing: CatchSpacing.space6) {
                Image(systemName: "mappin.circle.fill")
                    .frame(width: 16, alignment: .center)
                    .accessibilityHidden(true)
                Text(encounter.locationName)
            }
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
                .lineLimit(3)
        }
    }
}
