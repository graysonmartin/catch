import SwiftUI
import CatchCore

struct RemoteCatProfileView: View {
    let cat: CloudCat
    let encounters: [CloudEncounter]
    let owner: CloudUserProfile

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
            if !cat.photos.isEmpty || !cat.photoUrls.isEmpty {
                PhotoCarouselView(
                    photos: cat.photos,
                    photoUrls: cat.photoUrls,
                    height: 250,
                    cornerRadius: CatchTheme.cornerRadius
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
            NavigationLink {
                RemoteProfileContent(userID: owner.appleUserID, initialDisplayName: owner.displayName)
            } label: {
                HStack(spacing: CatchSpacing.space10) {
                    ownerAvatarView
                    VStack(alignment: .leading, spacing: CatchSpacing.space2) {
                        Text(owner.displayName)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(CatchTheme.textPrimary)
                        if let username = owner.username, !username.isEmpty {
                            Text("@\(username)")
                                .font(.caption)
                                .foregroundStyle(CatchTheme.textSecondary)
                        }
                    }
                    Spacer()
                }
            }
        } header: {
            Text(CatchStrings.CatProfile.ownerLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CatchTheme.textSecondary)
                .textCase(.uppercase)
        }
        .listRowBackground(CatchTheme.background)
        .listRowSeparator(.hidden)
    }

    @ViewBuilder
    private var ownerAvatarView: some View {
        if let avatarUrl = owner.avatarURL, !avatarUrl.isEmpty {
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
