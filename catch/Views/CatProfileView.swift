import SwiftUI

struct CatProfileView: View {
    @Bindable var cat: Cat
    @State private var showingAddCare = false
    @State private var showingEdit = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Photo header
                PhotoCarouselView(
                    photos: cat.photos,
                    height: 250,
                    cornerRadius: 16
                )
                .padding(.horizontal)

                // Info section
                VStack(spacing: 12) {
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
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)

                // Action buttons
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
                .padding(.horizontal)

                // Encounters section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Encounters (\(cat.encounters.count))")
                        .font(.headline)
                        .foregroundStyle(CatchTheme.textPrimary)

                    if cat.encounters.isEmpty {
                        Text("No encounters logged.")
                            .font(.subheadline)
                            .foregroundStyle(CatchTheme.textSecondary)
                    } else {
                        ForEach(cat.encounters.sorted(by: { $0.date > $1.date })) { encounter in
                            encounterRow(encounter)
                        }
                    }
                }
                .padding(.horizontal)

                // Care log section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Care Log (\(cat.careEntries.count))")
                        .font(.headline)
                        .foregroundStyle(CatchTheme.textPrimary)

                    if cat.careEntries.isEmpty {
                        Text("No care entries logged.")
                            .font(.subheadline)
                            .foregroundStyle(CatchTheme.textSecondary)
                    } else {
                        ForEach(cat.careEntries.sorted(by: { $0.startDate > $1.startDate })) { entry in
                            careRow(entry)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .background(CatchTheme.background)
        .navigationTitle(cat.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddCare) {
            AddCareEntryView(cat: cat)
        }
        .sheet(isPresented: $showingEdit) {
            EditCatView(cat: cat)
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
