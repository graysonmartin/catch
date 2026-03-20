import SwiftUI
import CatchCore

private enum Layout {
    static let thumbnailSize: CGFloat = 48
    static let carouselHeight: CGFloat = 200
}

struct RemoteFeedItemView: View {
    let encounter: CloudEncounter
    let cat: CloudCat?

    @State private var showDetail = false
    @State private var showReportSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: CatchSpacing.space12) {
            header
            photos
            encounterMetadata
            InteractionBar(encounterRecordName: encounter.recordName, showDetail: $showDetail)
        }
        .padding()
        .background(CatchTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadius))
        .shadow(color: .black.opacity(CatchTheme.cardShadowOpacity), radius: CatchTheme.cardShadowRadius, y: CatchTheme.cardShadowY)
        .accessibilityElement(children: .contain)
        .accessibilityHint(CatchStrings.Accessibility.feedCardHint)
        .sheet(isPresented: $showDetail) {
            EncounterDetailSheet(
                data: EncounterDetailData(remote: encounter, cat: cat, isFirstEncounter: false),
                isOwnEncounter: false
            )
        }
        .sheet(isPresented: $showReportSheet) {
            ReportEncounterView(encounterRecordName: encounter.recordName)
        }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack(spacing: CatchSpacing.space12) {
            CatPhotoView(
                photoData: cat?.photos.first,
                photoUrl: cat?.photoUrls.first,
                size: Layout.thumbnailSize,
                accessibilityName: cat?.displayName
            )

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
    private var photos: some View {
        let allPhotos = !encounter.photos.isEmpty ? encounter.photos : (cat?.photos ?? [])
        let allPhotoUrls = !encounter.photoUrls.isEmpty ? encounter.photoUrls : (cat?.photoUrls ?? [])
        if !allPhotos.isEmpty || !allPhotoUrls.isEmpty {
            PhotoCarouselView(
                photos: allPhotos,
                photoUrls: allPhotoUrls,
                height: Layout.carouselHeight,
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
            Label(breedName, systemImage: "pawprint.fill")
                .font(.subheadline)
                .foregroundStyle(CatchTheme.textSecondary)
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
                .lineLimit(3)
        }
    }
}
