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
        ScrollView {
            VStack(spacing: CatchSpacing.space20) {
                photoHeader
                nameAndBadges
                infoCard
                encountersSection
            }
            .padding(.bottom, CatchSpacing.space32)
        }
        .background(CatchTheme.background)
        .navigationTitle(cat.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Photo Header

    private var photoHeader: some View {
        Group {
            if !cat.photos.isEmpty || !cat.photoUrls.isEmpty {
                PhotoCarouselView(
                    photos: cat.photos,
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
            Text(cat.displayName)
                .font(.title2.weight(.bold))
                .foregroundStyle(cat.isUnnamed ? CatchTheme.textSecondary : CatchTheme.textPrimary)

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

    // MARK: - Owner Row

    private var ownerRow: some View {
        NavigationLink {
            RemoteProfileContent(userID: owner.appleUserID, initialDisplayName: owner.displayName)
        } label: {
            HStack(spacing: CatchSpacing.space8) {
                ownerAvatarView

                Text(owner.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(CatchTheme.textPrimary)

                if let username = owner.username, !username.isEmpty {
                    Text("@\(username)")
                        .font(.caption)
                        .foregroundStyle(CatchTheme.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
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

    // MARK: - Info Card

    private var hasAboutInfo: Bool {
        !cat.breed.isEmpty || !cat.estimatedAge.isEmpty || !cat.locationName.isEmpty || !cat.notes.isEmpty
    }

    @ViewBuilder
    private var infoCard: some View {
        if hasAboutInfo {
            VStack(alignment: .leading, spacing: CatchSpacing.space10) {
                Text(CatchStrings.CatProfile.aboutSection)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CatchTheme.textSecondary)
                    .textCase(.uppercase)

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

    // MARK: - Encounters

    private var encountersSection: some View {
        VStack(alignment: .leading, spacing: CatchSpacing.space10) {
            Text(CatchStrings.CatProfile.encountersHeader(sortedEncounters.count))
                .font(.caption.weight(.semibold))
                .foregroundStyle(CatchTheme.textSecondary)
                .textCase(.uppercase)
                .padding(.horizontal, CatchSpacing.space16)

            if sortedEncounters.isEmpty {
                Text(CatchStrings.CatProfile.noEncountersLoggedRemote)
                    .font(.subheadline)
                    .foregroundStyle(CatchTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, CatchSpacing.space24)
            } else {
                VStack(spacing: CatchSpacing.space8) {
                    ForEach(sortedEncounters, id: \.recordName) { encounter in
                        encounterRow(encounter)
                    }
                }
                .padding(.horizontal, CatchSpacing.space16)
            }
        }
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

    private func encounterRow(_ encounter: CloudEncounter) -> some View {
        HStack(spacing: CatchSpacing.space12) {
            encounterThumbnail(encounter)

            VStack(alignment: .leading, spacing: CatchSpacing.space2) {
                Text(encounter.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(CatchTheme.textPrimary)
                if !encounter.locationName.isEmpty {
                    Label(encounter.locationName, systemImage: "mappin")
                        .font(.caption)
                        .foregroundStyle(CatchTheme.textSecondary)
                }
                if !encounter.notes.isEmpty {
                    Text(encounter.notes)
                        .font(.caption)
                        .foregroundStyle(CatchTheme.textSecondary)
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding(CatchSpacing.space12)
        .background(CatchTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusTight))
        .shadow(
            color: .black.opacity(CatchTheme.cardShadowOpacity),
            radius: CatchTheme.cardShadowRadius,
            y: CatchTheme.cardShadowY
        )
    }

    @ViewBuilder
    private func encounterThumbnail(_ encounter: CloudEncounter) -> some View {
        if let firstUrl = encounter.photoUrls.first {
            RemoteImageView(urlString: ThumbnailURL.thumbnailOrOriginal(for: firstUrl)) {
                thumbnailPlaceholder
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusTight))
        } else {
            thumbnailPlaceholder
        }
    }

    private var thumbnailPlaceholder: some View {
        Image(systemName: "camera.fill")
            .font(.system(size: 16))
            .foregroundStyle(CatchTheme.primary.opacity(0.6))
            .frame(width: 48, height: 48)
            .background(CatchTheme.secondary.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusTight))
    }
}
