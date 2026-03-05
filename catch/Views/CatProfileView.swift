import SwiftUI
import SwiftData
import CatchCore

struct CatProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(CKCatSyncService.self) private var catSyncService: CKCatSyncService?
    @Environment(CKEncounterSyncService.self) private var encounterSyncService: CKEncounterSyncService?
    @Environment(ToastManager.self) private var toastManager
    @Bindable var cat: Cat
    @State private var showingEdit = false
    @State private var showingDeleteCat = false
    @State private var encounterToEdit: Encounter?
    @State private var showingLogEncounter = false
    @State private var encounterToDelete: Encounter?
    @State private var isDeleting = false

    private var sortedEncounters: [Encounter] {
        cat.encounters.sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            // Photo header
            Section {
                if !cat.photos.isEmpty {
                    PhotoCarouselView(
                        photos: cat.photos,
                        height: 250,
                        cornerRadius: 16
                    )
                }
            }
            .listRowInsets(EdgeInsets(top: 0, leading: CatchSpacing.space16, bottom: 0, trailing: CatchSpacing.space16))
            .listRowBackground(CatchTheme.background)
            .listRowSeparator(.hidden)

            // Info section
            Section {
                HStack {
                    Text(cat.displayName)
                        .font(.title.weight(.bold))
                        .foregroundStyle(cat.isUnnamed ? CatchTheme.textSecondary : CatchTheme.textPrimary)
                    if cat.isSteven {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundStyle(CatchTheme.primary)
                    }
                    if cat.isOwned {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(CatchTheme.primary)
                    }
                    Spacer()
                }

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

                Text(CatchStrings.CatProfile.firstSeen(cat.createdAt))
                    .font(.caption)
                    .foregroundStyle(CatchTheme.textSecondary)
            }
            .listRowBackground(CatchTheme.background)
            .listRowSeparator(.hidden)

            // Action buttons
            Section {
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
            }
            .listRowInsets(EdgeInsets(top: CatchSpacing.space4, leading: CatchSpacing.space16, bottom: CatchSpacing.space4, trailing: CatchSpacing.space16))
            .listRowBackground(CatchTheme.background)
            .listRowSeparator(.hidden)

            // Encounters section
            Section {
                if sortedEncounters.isEmpty {
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
                    .listRowBackground(CatchTheme.background)
                } else {
                    ForEach(sortedEncounters) { encounter in
                        encounterRow(encounter)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                encounterToEdit = encounter
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(CatchStrings.Common.delete, role: .destructive) {
                                    encounterToDelete = encounter
                                }
                            }
                    }
                }
            } header: {
                Text(CatchStrings.CatProfile.encountersHeader(sortedEncounters.count))
                    .font(.headline)
                    .foregroundStyle(CatchTheme.textPrimary)
                    .textCase(nil)
            }
            .listRowBackground(CatchTheme.background)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: CatchSpacing.space4, leading: CatchSpacing.space16, bottom: CatchSpacing.space4, trailing: CatchSpacing.space16))

            // Delete cat
            Section {
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
                }
                .disabled(isDeleting)
            }
            .listRowBackground(CatchTheme.background)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(CatchTheme.background)
        .navigationTitle(cat.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $encounterToEdit) { encounter in
            EditEncounterView(encounter: encounter)
        }
        .sheet(isPresented: $showingEdit) {
            EditCatView(cat: cat)
        }
        .sheet(isPresented: $showingLogEncounter) {
            LogEncounterView(preselectedCat: cat)
        }
        .alert(CatchStrings.CatProfile.deleteEncounterTitle, isPresented: Binding(
            get: { encounterToDelete != nil },
            set: { if !$0 { encounterToDelete = nil } }
        )) {
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
            Text(CatchStrings.CatProfile.deleteEncounterMessage)
        }
        .alert(CatchStrings.CatProfile.deleteCatTitle(name: cat.displayName), isPresented: $showingDeleteCat) {
            Button(CatchStrings.Common.delete, role: .destructive) {
                Task { await deleteCat() }
            }
            Button(CatchStrings.Common.cancel, role: .cancel) {}
        } message: {
            Text(CatchStrings.CatProfile.deleteCatMessage)
        }
    }

    // MARK: - Delete Actions

    private func deleteEncounter(_ encounter: Encounter) async {
        if let recordName = encounter.cloudKitRecordName {
            do {
                try await encounterSyncService?.deleteEncounter(recordName: recordName)
            } catch {
                toastManager.showError(CatchStrings.Toast.deleteSyncFailed)
                return
            }
        }
        modelContext.delete(encounter)
    }

    private func deleteCat() async {
        isDeleting = true
        defer { isDeleting = false }

        // Delete all encounter records from CloudKit first
        for encounter in cat.encounters {
            if let recordName = encounter.cloudKitRecordName {
                do {
                    try await encounterSyncService?.deleteEncounter(recordName: recordName)
                    encounter.cloudKitRecordName = nil
                } catch {
                    toastManager.showError(CatchStrings.Toast.deleteSyncFailed)
                    return
                }
            }
        }

        // Delete cat record from CloudKit
        if let recordName = cat.cloudKitRecordName {
            do {
                try await catSyncService?.deleteCat(recordName: recordName)
            } catch {
                toastManager.showError(CatchStrings.Toast.deleteSyncFailed)
                return
            }
        }

        // Delete locally
        modelContext.delete(cat)
        dismiss()
    }

    // MARK: - Subviews

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: CatchSpacing.space8) {
            Image(systemName: icon)
                .foregroundStyle(CatchTheme.primary)
                .frame(width: 20)
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

    private func encounterRow(_ encounter: Encounter) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: CatchSpacing.space2) {
                Text(encounter.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(CatchTheme.textPrimary)
                if !encounter.location.name.isEmpty {
                    Text(encounter.location.name)
                        .font(.caption)
                        .foregroundStyle(CatchTheme.textSecondary)
                }
                if !encounter.notes.isEmpty {
                    Text(encounter.notes)
                        .font(.caption)
                        .foregroundStyle(CatchTheme.textSecondary)
                }
            }
            Spacer()
            Image(systemName: "pencil")
                .font(.caption)
                .foregroundStyle(CatchTheme.textSecondary.opacity(0.5))
        }
        .padding(CatchSpacing.space12)
        .background(CatchTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusTight))
    }
}
