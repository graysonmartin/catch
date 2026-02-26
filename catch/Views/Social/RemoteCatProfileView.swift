import SwiftUI

struct RemoteCatProfileView: View {
    let cat: CloudCat
    let encounters: [CloudEncounter]
    let ownerName: String

    private var sortedEncounters: [CloudEncounter] {
        encounters
            .filter { $0.catRecordName == cat.recordName }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            photoSection
            infoSection
            ownerSection
            encountersSection
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(CatchTheme.background)
        .navigationTitle(cat.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Sections

    private var photoSection: some View {
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
    }

    private var infoSection: some View {
        Section {
            HStack {
                Text(cat.displayName)
                    .font(.title.weight(.bold))
                    .foregroundStyle(cat.isUnnamed ? CatchTheme.textSecondary : CatchTheme.textPrimary)
                if cat.isOwned {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(CatchTheme.primary)
                }
                Spacer()
            }

            if !cat.breed.isEmpty {
                infoRow(icon: "pawprint.fill", label: CatchStrings.Common.breed, value: cat.breed)
            }
            if !cat.estimatedAge.isEmpty {
                infoRow(icon: "calendar", label: CatchStrings.Common.age, value: cat.estimatedAge)
            }
            if !cat.locationName.isEmpty {
                infoRow(icon: "mappin.circle.fill", label: CatchStrings.Common.location, value: cat.locationName)
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
    }

    private var ownerSection: some View {
        Section {
            HStack(spacing: CatchSpacing.space8) {
                Image(systemName: "person.crop.circle.fill")
                    .foregroundStyle(CatchTheme.secondary)
                Text(ownerName)
                    .font(.subheadline)
                    .foregroundStyle(CatchTheme.textPrimary)
            }
        }
        .listRowBackground(CatchTheme.background)
        .listRowSeparator(.hidden)
    }

    private var encountersSection: some View {
        Section {
            if sortedEncounters.isEmpty {
                Text(CatchStrings.CatProfile.noEncountersLoggedRemote)
                    .font(.subheadline)
                    .foregroundStyle(CatchTheme.textSecondary)
            } else {
                ForEach(sortedEncounters, id: \.recordName) { encounter in
                    encounterRow(encounter)
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
    }

    // MARK: - Row helpers

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

    private func encounterRow(_ encounter: CloudEncounter) -> some View {
        VStack(alignment: .leading, spacing: CatchSpacing.space2) {
            Text(encounter.date.formatted(date: .abbreviated, time: .shortened))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(CatchTheme.textPrimary)
            if !encounter.locationName.isEmpty {
                Text(encounter.locationName)
                    .font(.caption)
                    .foregroundStyle(CatchTheme.textSecondary)
            }
            if !encounter.notes.isEmpty {
                Text(encounter.notes)
                    .font(.caption)
                    .foregroundStyle(CatchTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(CatchSpacing.space12)
        .background(CatchTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusTight))
    }
}
