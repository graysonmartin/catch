import SwiftUI
import CatchCore

enum FeedCardLayout {
    static let thumbnailSize: CGFloat = 48
    static let carouselHeight: CGFloat = 240
    static let pillHorizontalPadding: CGFloat = 6
    static let pillVerticalPadding: CGFloat = 2
    static let pillCornerRadius: CGFloat = 4
    static let pillActiveBackgroundOpacity: Double = 0.15
    static let pillInactiveBackgroundOpacity: Double = 0.1
}

struct FeedItemView: View {
    let encounter: Encounter

    @Environment(EncounterDataService.self) private var encounterDataService
    @Environment(CatDataService.self) private var catDataService
    @Environment(FeedDataService.self) private var feedDataService
    @Environment(ToastManager.self) private var toastManager

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
        .accessibilityElement(children: .contain)
        .accessibilityHint(CatchStrings.Accessibility.feedCardHint)
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
            CatPhotoView(
                photoData: nil,
                photoUrl: encounter.cat?.photoUrls.first,
                size: FeedCardLayout.thumbnailSize,
                accessibilityName: encounter.cat?.displayName
            )

            VStack(alignment: .leading, spacing: CatchSpacing.space2) {
                Text(encounter.cat?.displayName ?? CatchStrings.Feed.unknownCat)
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

            if encounter.cat?.isOwned == true {
                Image(systemName: "heart.fill")
                    .foregroundStyle(CatchTheme.primary)
                    .font(.caption)
                    .accessibilityLabel(CatchStrings.Accessibility.ownedCat)
            }

            overflowMenu
        }
    }

    // MARK: - Photos

    @ViewBuilder
    private var photoSection: some View {
        let urls = !encounter.photoUrls.isEmpty ? encounter.photoUrls : (encounter.cat?.photoUrls ?? [])
        if !urls.isEmpty {
            PhotoCarouselView(photos: [], photoUrls: urls, height: FeedCardLayout.carouselHeight, cornerRadius: CatchTheme.cornerRadiusSmall, onTap: { showDetail = true })
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
        if !encounter.location.name.isEmpty {
            HStack(spacing: CatchSpacing.space6) {
                Image(systemName: "mappin.circle.fill")
                    .frame(width: 16, alignment: .center)
                    .accessibilityHidden(true)
                Text(encounter.location.name)
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

    // MARK: - Interaction

    @ViewBuilder
    private var interactionSection: some View {
        InteractionBar(encounterRecordName: encounter.id.uuidString, showDetail: $showDetail, isOwnEncounter: true, encounterDate: encounter.date)
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
                .frame(minWidth: CatchTheme.minTapTarget, minHeight: CatchTheme.minTapTarget)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(CatchStrings.Accessibility.moreOptions)
    }

    // MARK: - Actions

    private func deleteEncounter() {
        Task {
            do {
                try await encounterDataService.deleteEncounter(id: encounter.id)
                feedDataService.removeEncounter(id: encounter.id)
                // Reload cats -- the DB trigger may have deleted the orphaned cat.
                try await catDataService.loadCats()
            } catch {
                toastManager.showError(CatchStrings.Toast.deleteSyncFailed)
            }
        }
    }

    // MARK: - Helpers

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
}
