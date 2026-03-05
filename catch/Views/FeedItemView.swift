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

    @Environment(\.modelContext) private var modelContext
    @Environment(CKEncounterSyncService.self) private var encounterSyncService: CKEncounterSyncService?

    @State private var showDetail = false
    @State private var showEditEncounter = false
    @State private var showDeleteConfirmation = false

    private var isFirstEncounter: Bool {
        guard let cat = encounter.cat else { return false }
        guard let earliest = cat.encounters.min(by: { $0.date < $1.date }) else { return false }
        return earliest.id == encounter.id
    }

    private var isUnnamed: Bool {
        encounter.cat?.isUnnamed ?? false
    }

    private var detailData: EncounterDetailData {
        EncounterDetailData(local: encounter, isFirstEncounter: isFirstEncounter)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CatchSpacing.space12) {
            header
            photoSection
            encounterMetadata
            interactionSection
        }
        .padding()
        .background(CatchTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadius))
        .shadow(color: .black.opacity(CatchTheme.cardShadowOpacity), radius: CatchTheme.cardShadowRadius, y: CatchTheme.cardShadowY)
        .contentShape(Rectangle())
        .onTapGesture { showDetail = true }
        .sheet(isPresented: $showDetail) {
            EncounterDetailSheet(data: detailData)
        }
        .sheet(isPresented: $showEditEncounter) {
            EditEncounterView(encounter: encounter)
        }
        .alert(CatchStrings.Feed.deleteEncounterTitle, isPresented: $showDeleteConfirmation) {
            Button(CatchStrings.Common.delete, role: .destructive) {
                deleteEncounter()
            }
            Button(CatchStrings.Common.cancel, role: .cancel) {}
        } message: {
            Text(CatchStrings.Feed.deleteEncounterMessage)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: CatchSpacing.space12) {
            CatPhotoView(photoData: encounter.cat?.photos.first, size: FeedItemLayout.thumbnailSize)

            VStack(alignment: .leading, spacing: CatchSpacing.space2) {
                HStack(spacing: CatchSpacing.space4) {
                    Text(encounter.cat?.displayName ?? CatchStrings.Feed.unknownCat)
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

            if encounter.cat?.isOwned == true {
                Image(systemName: "heart.fill")
                    .foregroundStyle(CatchTheme.primary)
                    .font(.caption)
            }

            overflowMenu
        }
    }

    // MARK: - Photos

    @ViewBuilder
    private var photoSection: some View {
        if let photos = (!encounter.photos.isEmpty ? encounter.photos : encounter.cat?.photos),
           !photos.isEmpty {
            PhotoCarouselView(photos: photos, height: FeedItemLayout.carouselHeight, cornerRadius: CatchTheme.cornerRadiusSmall, onTap: { showDetail = true })
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
        if let breedName = encounter.cat?.breed, !breedName.isEmpty {
            Label(breedName, systemImage: "pawprint.fill")
                .font(.subheadline)
                .foregroundStyle(CatchTheme.textSecondary)
        }
    }

    @ViewBuilder
    private var location: some View {
        if !encounter.location.name.isEmpty {
            Label(encounter.location.name, systemImage: "mappin.circle.fill")
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

    // MARK: - Interaction

    @ViewBuilder
    private var interactionSection: some View {
        if let recordName = encounter.cloudKitRecordName {
            InteractionBar(encounterRecordName: recordName, showDetail: $showDetail, isOwnEncounter: true)
        } else {
            HStack {
                Spacer()
                (Text(CatchStrings.Feed.spottedByPrefix)
                    .foregroundStyle(CatchTheme.textSecondary) +
                Text(CatchStrings.Social.you)
                    .foregroundStyle(CatchTheme.primary))
                    .font(.caption.weight(.medium))
            }
        }
    }

    // MARK: - Overflow Menu

    private var overflowMenu: some View {
        Menu {
            Button {
                showEditEncounter = true
            } label: {
                Label(CatchStrings.Feed.editEncounter, systemImage: "pencil")
            }

            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label(CatchStrings.Feed.deleteEncounter, systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.body)
                .foregroundStyle(CatchTheme.textSecondary)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
    }

    // MARK: - Actions

    private func deleteEncounter() {
        let recordName = encounter.cloudKitRecordName
        modelContext.delete(encounter)
        if let recordName {
            Task { try? await encounterSyncService?.deleteEncounter(recordName: recordName) }
        }
    }

    // MARK: - Helpers

    private func pill(text: String, isActive: Bool) -> some View {
        Text(text)
            .font(.system(size: PillLayout.fontSize, weight: .bold))
            .foregroundStyle(isActive ? CatchTheme.primary : CatchTheme.textSecondary)
            .padding(.horizontal, PillLayout.horizontalPadding)
            .padding(.vertical, PillLayout.verticalPadding)
            .background(
                RoundedRectangle(cornerRadius: PillLayout.cornerRadius)
                    .fill(
                        isActive
                            ? CatchTheme.primary.opacity(PillLayout.activeBackgroundOpacity)
                            : CatchTheme.textSecondary.opacity(PillLayout.inactiveBackgroundOpacity)
                    )
            )
    }
}
