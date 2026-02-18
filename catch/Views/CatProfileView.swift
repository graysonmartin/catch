import SwiftUI

struct CatProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var cat: Cat
    @State private var showingAddCare = false
    @State private var showingEdit = false
    @State private var showingDeleteCat = false
    @State private var encounterToDelete: Encounter?
    @State private var careEntryToDelete: CareEntry?

    private var sortedEncounters: [Encounter] {
        cat.encounters.sorted { $0.date > $1.date }
    }

    private var sortedCareEntries: [CareEntry] {
        cat.careEntries.sorted { $0.startDate > $1.startDate }
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
                    if cat.isOwned {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(CatchTheme.primary)
                    }
                    Spacer()
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
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        showingAddCare = true
                    } label: {
                        Label("Add Care", systemImage: "heart.text.square")
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(CatchTheme.primary)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
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

            // Care log section
            Section {
                if sortedCareEntries.isEmpty {
                    Text("No care entries logged.")
                        .font(.subheadline)
                        .foregroundStyle(CatchTheme.textSecondary)
                        .listRowBackground(CatchTheme.background)
                } else {
                    ForEach(sortedCareEntries) { entry in
                        careRow(entry)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("Delete", role: .destructive) {
                                    careEntryToDelete = entry
                                }
                            }
                    }
                }
            } header: {
                Text("Care Log (\(cat.careEntries.count))")
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
        .sheet(isPresented: $showingAddCare) {
            AddCareEntryView(cat: cat)
        }
        .sheet(isPresented: $showingEdit) {
            EditCatView(cat: cat)
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
        .alert("delete care entry?", isPresented: Binding(
            get: { careEntryToDelete != nil },
            set: { if !$0 { careEntryToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let entry = careEntryToDelete {
                    modelContext.delete(entry)
                    careEntryToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                careEntryToDelete = nil
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
            Text("this deletes all their encounters and care entries too. absolutely no undo.")
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
        }
        .padding(12)
        .background(CatchTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func careRow(_ entry: CareEntry) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(entry.startDate.formatted(date: .abbreviated, time: .omitted)) - \(entry.endDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(CatchTheme.textPrimary)
                Text("\(entry.durationDays) day\(entry.durationDays == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(CatchTheme.primary)
                if !entry.notes.isEmpty {
                    Text(entry.notes)
                        .font(.caption)
                        .foregroundStyle(CatchTheme.textSecondary)
                }
            }
            Spacer()
        }
        .padding(12)
        .background(CatchTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
