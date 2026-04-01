import SwiftUI
import CatchCore

struct CatProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CatDataService.self) private var catDataService
    @Environment(EncounterDataService.self) private var encounterDataService
    @Environment(FeedDataService.self) private var feedDataService
    @Environment(ToastManager.self) private var toastManager
    @Environment(SupabaseAuthService.self) private var authService
    @Environment(ProfileSyncService.self) private var profileSyncService

    @State private var cat: Cat
    @State private var showingEdit = false
    @State private var showingDeleteCat = false
    @State private var encounterToEdit: Encounter?
    @State private var showingLogEncounter = false
    @State private var encounterToDelete: Encounter?
    @State private var isDeleting = false
    @State private var ownerProfile: CloudUserProfile?
    @State private var encounterRowHeight: CGFloat = 76

    init(cat: Cat) {
        _cat = State(initialValue: cat)
    }

    private var sortedEncounters: [Encounter] {
        cat.encounters.sorted { $0.date > $1.date }
    }

    private var isLastEncounter: Bool {
        cat.encounters.count == 1
    }

    var body: some View {
        ScrollView {
            VStack(spacing: CatchSpacing.space20) {
                photoHeader
                nameAndBadges
                actionButtons
                infoCard
                encountersSection
                deleteSection
            }
            .padding(.bottom, CatchSpacing.space32)
        }
        .background(CatchTheme.background)
        .navigationTitle(cat.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $encounterToEdit, onDismiss: {
            Task { await refreshCat() }
        }) { encounter in
            EditEncounterView(encounter: encounter)
        }
        .sheet(isPresented: $showingEdit, onDismiss: {
            Task { await refreshCat() }
        }) {
            EditCatView(cat: cat)
        }
        .sheet(isPresented: $showingLogEncounter, onDismiss: {
            Task { await refreshCat() }
        }) {
            LogEncounterView(preselectedCat: cat)
        }
        .alert(
            isLastEncounter
                ? CatchStrings.CatProfile.deleteLastEncounterTitle
                : CatchStrings.CatProfile.deleteEncounterTitle,
            isPresented: Binding(
                get: { encounterToDelete != nil },
                set: { if !$0 { encounterToDelete = nil } }
            )
        ) {
            Button(CatchStrings.Common.delete, role: .destructive) {
                if let encounter = encounterToDelete {
                    Task { await deleteEncounter(encounter) }
                    encounterToDelete = nil
                }
            }
            Button(CatchStrings.Common.cancel, role: .cancel) {
                encounterToDelete = nil
            }
        } message: {
            Text(
                isLastEncounter
                    ? CatchStrings.CatProfile.deleteLastEncounterMessage
                    : CatchStrings.CatProfile.deleteEncounterMessage
            )
        }
        .alert(CatchStrings.CatProfile.deleteCatTitle(name: cat.displayName), isPresented: $showingDeleteCat) {
            Button(CatchStrings.Common.delete, role: .destructive) {
                Task { await deleteCat() }
            }
            Button(CatchStrings.Common.cancel, role: .cancel) {}
        } message: {
            Text(CatchStrings.CatProfile.deleteCatMessage)
        }
        .task {
            async let catRefresh: Void = refreshCat()
            async let ownerLoad: Void = loadOwnerProfile()
            _ = await (catRefresh, ownerLoad)
        }
    }

    // MARK: - Photo Header

    private var photoHeader: some View {
        Group {
            if !cat.photoUrls.isEmpty {
                PhotoCarouselView(
                    photos: [],
                    photoUrls: cat.photoUrls,
                    height: 280,
                    cornerRadius: CatchTheme.cornerRadius,
                    isTappable: true
                )
            } else {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(CatchTheme.primary.opacity(0.4))
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background(CatchTheme.secondary.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadius))
            }
        }
        .padding(.horizontal, CatchSpacing.space16)
    }

    // MARK: - Name & Badges

    private var nameAndBadges: some View {
        VStack(spacing: CatchSpacing.space4) {
            HStack(spacing: CatchSpacing.space6) {
                Text(cat.displayName)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(cat.isUnnamed ? CatchTheme.textSecondary : CatchTheme.textPrimary)
                if cat.isSteven {
                    Image(systemName: "crown.fill")
                        .font(.caption)
                        .foregroundStyle(CatchTheme.primary)
                        .accessibilityLabel(CatchStrings.Accessibility.stevenBadge)
                }
            }

            if cat.isOwned {
                Text(CatchStrings.CatProfile.ownedBadge)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, CatchSpacing.space8)
                    .padding(.vertical, CatchSpacing.space2)
                    .background(CatchTheme.primary)
                    .clipShape(Capsule())
            }

            ownerRow
        }
        .padding(.horizontal, CatchSpacing.space16)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: CatchSpacing.space12) {
            Button {
                showingEdit = true
            } label: {
                Label(CatchStrings.Common.edit, systemImage: "pencil")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, CatchSpacing.space12)
                    .background(CatchTheme.secondary)
                    .foregroundStyle(CatchTheme.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusSmall))
            }

            Button {
                showingLogEncounter = true
            } label: {
                Label(CatchStrings.CatProfile.spotted, systemImage: "eye.fill")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, CatchSpacing.space12)
                    .background(CatchTheme.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusSmall))
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, CatchSpacing.space16)
    }

    // MARK: - Info Card

    private var hasBreed: Bool {
        if let breed = cat.breed, !breed.isEmpty { return true }
        return false
    }

    private var hasAboutInfo: Bool {
        hasBreed || !cat.estimatedAge.isEmpty || !cat.location.name.isEmpty || !cat.notes.isEmpty
    }

    @ViewBuilder
    private var infoCard: some View {
        if hasAboutInfo {
            VStack(alignment: .leading, spacing: CatchSpacing.space10) {
                Text(CatchStrings.CatProfile.aboutSection)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CatchTheme.textSecondary)
                    .textCase(.uppercase)

                if let breed = cat.breed, !breed.isEmpty {
                    infoRow(icon: "pawprint.fill", label: CatchStrings.Common.breed, value: breed)
                }
                if !cat.estimatedAge.isEmpty {
                    infoRow(icon: "calendar", label: CatchStrings.Common.age, value: cat.estimatedAge)
                }
                if !cat.location.name.isEmpty {
                    infoRow(icon: "mappin.circle.fill", label: CatchStrings.Common.location, value: cat.location.name)
                }
                if !cat.notes.isEmpty {
                    infoRow(icon: "note.text", label: CatchStrings.Common.notes, value: cat.notes)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(CatchSpacing.space16)
            .background(CatchTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadius))
            .shadow(
                color: .black.opacity(CatchTheme.cardShadowOpacity),
                radius: CatchTheme.cardShadowRadius,
                y: CatchTheme.cardShadowY
            )
            .padding(.horizontal, CatchSpacing.space16)
        }
    }

    @ViewBuilder
    private var ownerRow: some View {
        if let profile = ownerProfile {
            NavigationLink {
                RemoteProfileContent(userID: profile.appleUserID, initialDisplayName: profile.displayName)
            } label: {
                HStack(spacing: CatchSpacing.space8) {
                    ownerAvatarView(profile)

                    Text(profile.displayName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(CatchTheme.textPrimary)

                    if let username = profile.username, !username.isEmpty {
                        Text("@\(username)")
                            .font(.caption)
                            .foregroundStyle(CatchTheme.textSecondary)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func ownerAvatarView(_ profile: CloudUserProfile) -> some View {
        if let avatarUrl = profile.avatarURL, !avatarUrl.isEmpty {
            RemoteImageView(urlString: avatarUrl) {
                ownerAvatarPlaceholder
            }
            .frame(width: 36, height: 36)
            .clipShape(Circle())
        } else {
            ownerAvatarPlaceholder
        }
    }

    private var ownerAvatarPlaceholder: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 36, height: 36)
            .foregroundStyle(CatchTheme.secondary)
    }

    // MARK: - Encounters

    private var encountersSection: some View {
        VStack(alignment: .leading, spacing: CatchSpacing.space10) {
            Text(CatchStrings.CatProfile.encountersHeader(sortedEncounters.count))
                .font(.caption.weight(.semibold))
                .foregroundStyle(CatchTheme.textSecondary)
                .textCase(.uppercase)
                .padding(.horizontal, CatchSpacing.space16)

            if sortedEncounters.isEmpty {
                encountersEmptyState
            } else {
                encountersList
            }
        }
    }

    private var encountersEmptyState: some View {
        VStack(spacing: CatchSpacing.space8) {
            Text(CatchStrings.CatProfile.noEncountersLogged)
                .font(.subheadline)
                .foregroundStyle(CatchTheme.textSecondary)
            Button {
                showingLogEncounter = true
            } label: {
                Text(CatchStrings.CatProfile.logSighting)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(CatchTheme.primary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, CatchSpacing.space24)
    }

    private var encountersList: some View {
        List {
            ForEach(sortedEncounters) { encounter in
                EncounterRowView(encounter: encounter)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        var encounterWithCat = encounter
                        encounterWithCat.cat = cat
                        encounterToEdit = encounterWithCat
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button {
                            encounterToDelete = encounter
                        } label: {
                            Label(CatchStrings.Common.delete, systemImage: "trash")
                        }
                        .tint(.red)
                    }
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(
                                key: RowHeightPreferenceKey.self,
                                value: geo.size.height
                            )
                        }
                    )
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(
                top: CatchSpacing.space4,
                leading: CatchSpacing.space16,
                bottom: CatchSpacing.space4,
                trailing: CatchSpacing.space16
            ))
        }
        .listStyle(.plain)
        .scrollDisabled(true)
        .scrollContentBackground(.hidden)
        .frame(height: CGFloat(sortedEncounters.count) * (encounterRowHeight + CatchSpacing.space8))
        .onPreferenceChange(RowHeightPreferenceKey.self) { height in
            if height > 0 {
                encounterRowHeight = height
            }
        }
    }

    // MARK: - Delete

    private var deleteSection: some View {
        Button(role: .destructive) {
            showingDeleteCat = true
        } label: {
            HStack {
                Spacer()
                if isDeleting {
                    ProgressView()
                } else {
                    Label(CatchStrings.CatProfile.deleteThisCat, systemImage: "trash")
                        .font(.subheadline.weight(.medium))
                }
                Spacer()
            }
            .padding(.vertical, CatchSpacing.space12)
        }
        .disabled(isDeleting)
        .padding(.horizontal, CatchSpacing.space16)
        .padding(.top, CatchSpacing.space8)
    }

    // MARK: - Subviews

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: CatchSpacing.space8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(CatchTheme.primary)
                .frame(width: 20, height: 20, alignment: .center)
            VStack(alignment: .leading, spacing: CatchSpacing.space2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(CatchTheme.textSecondary)
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(CatchTheme.textPrimary)
            }
            Spacer()
        }
    }

    // MARK: - Data

    private func refreshCat() async {
        guard let refreshed = try? await catDataService.fetchCat(id: cat.id) else { return }
        cat = refreshed
    }

    private func loadOwnerProfile() async {
        guard let userID = authService.authState.user?.id else { return }
        guard let profile = try? await profileSyncService.fetchProfile(userID: userID) else { return }
        ownerProfile = profile
    }

    private func deleteEncounter(_ encounter: Encounter) async {
        do {
            try await encounterDataService.deleteEncounter(id: encounter.id)
            try await catDataService.loadCats()
            feedDataService.removeEncounter(id: encounter.id)

            // The DB trigger deletes the cat when its last encounter is removed.
            // If the cat no longer exists, dismiss the profile.
            let refreshed = try? await catDataService.fetchCat(id: cat.id)
            if let refreshed {
                cat = refreshed
            } else {
                dismiss()
            }
        } catch {
            toastManager.showError(CatchStrings.Toast.deleteSyncFailed)
        }
    }

    private func deleteCat() async {
        isDeleting = true
        defer { isDeleting = false }

        do {
            let encounterIDs = cat.encounters.map(\.id)
            try await catDataService.deleteCat(cat)
            for id in encounterIDs {
                feedDataService.removeEncounter(id: id)
            }
            dismiss()
        } catch {
            toastManager.showError(CatchStrings.Toast.deleteSyncFailed)
        }
    }
}

// MARK: - Row Height Measurement

private struct RowHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        let next = nextValue()
        if next > value { value = next }
    }
}
