import SwiftUI

struct CatProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var cat: Cat
    @State private var showingEdit = false
    @State private var showingDeleteCat = false
    @State private var encounterToEdit: Encounter?
    @State private var showingLogEncounter = false
    @State private var encounterToDelete: Encounter?

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
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            .listRowBackground(CatchTheme.background)
            .listRowSeparator(.hidden)

            // Info section
            Section {
                HStack {
                    Text(cat.name)
                        .font(.title.weight(.bold))
                        .foregroundStyle(CatchTheme.textPrimary)
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
                    infoRow(icon: "pawprint.fill", label: "Breed", value: breed)
                }
                if !cat.estimatedAge.isEmpty {
                    infoRow(icon: "calendar", label: "Age", value: cat.estimatedAge)
                }
                if !cat.location.name.isEmpty {
                    infoRow(icon: "mappin.circle.fill", label: "Location", value: cat.location.name)
                }
                if !cat.notes.isEmpty {
                    infoRow(icon: "note.text", label: "Notes", value: cat.notes)
                }

                Text("First seen \(cat.createdAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(CatchTheme.textSecondary)
            }
            .listRowBackground(CatchTheme.background)
            .listRowSeparator(.hidden)

            // Action buttons
            Section {
                HStack(spacing: 12) {
                    Button {
                        showingEdit = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(CatchTheme.secondary)
                            .foregroundStyle(CatchTheme.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusSmall))
                    }

                    Button {
                        showingLogEncounter = true
                    } label: {
                        Label("Spotted", systemImage: "eye.fill")
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(CatchTheme.primary)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusSmall))
                    }
                }
                .buttonStyle(.plain)
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            .listRowBackground(CatchTheme.background)
            .listRowSeparator(.hidden)

            // Encounters section
            Section {
                if sortedEncounters.isEmpty {
                    Text("No encounters logged.")
                        .font(.subheadline)
                        .foregroundStyle(CatchTheme.textSecondary)
                        .listRowBackground(CatchTheme.background)
                } else {
                    ForEach(sortedEncounters) { encounter in
                        encounterRow(encounter)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                encounterToEdit = encounter
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("Delete", role: .destructive) {
                                    encounterToDelete = encounter
                                }
                            }
                    }
                }
            } header: {
                Text("Encounters (\(cat.encounters.count))")
                    .font(.headline)
                    .foregroundStyle(CatchTheme.textPrimary)
                    .textCase(nil)
            }
            .listRowBackground(CatchTheme.background)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))

            // Delete cat
            Section {
                Button(role: .destructive) {
                    showingDeleteCat = true
                } label: {
                    HStack {
                        Spacer()
                        Label("delete this cat", systemImage: "trash")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                    }
                }
            }
            .listRowBackground(CatchTheme.background)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(CatchTheme.background)
        .navigationTitle(cat.name)
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
        .alert("delete encounter?", isPresented: Binding(
            get: { encounterToDelete != nil },
            set: { if !$0 { encounterToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let encounter = encounterToDelete {
                    modelContext.delete(encounter)
                    encounterToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                encounterToDelete = nil
            }
        } message: {
            Text("gone forever. no take-backs.")
        }
        .alert("delete \(cat.name)?", isPresented: $showingDeleteCat) {
            Button("Delete", role: .destructive) {
                modelContext.delete(cat)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("this deletes all their encounters too. absolutely no undo.")
        }
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(CatchTheme.primary)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
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
            VStack(alignment: .leading, spacing: 2) {
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
        .padding(12)
        .background(CatchTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusTight))
    }
}
