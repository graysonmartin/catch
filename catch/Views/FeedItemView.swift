import SwiftUI

struct FeedItemView: View {
    let encounter: Encounter

    private var isFirstEncounter: Bool {
        guard let cat = encounter.cat else { return false }
        guard let earliest = cat.encounters.min(by: { $0.date < $1.date }) else { return false }
        return earliest.id == encounter.id
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: photo + name + date
            HStack(spacing: 12) {
                CatPhotoView(photoData: encounter.cat?.photos.first, size: 48)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(encounter.cat?.name ?? "Unknown Cat")
                            .font(.headline)
                            .foregroundStyle(CatchTheme.textPrimary)
                        Text(isFirstEncounter ? "NEW" : "REPEAT")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(isFirstEncounter ? CatchTheme.primary : CatchTheme.textSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(isFirstEncounter ? CatchTheme.primary.opacity(0.15) : CatchTheme.textSecondary.opacity(0.1))
                            )
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
            }

            // Photo (larger) if available
            if let photoData = encounter.cat?.photos.first,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Location
            if !encounter.location.name.isEmpty {
                Label(encounter.location.name, systemImage: "mappin.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(CatchTheme.textSecondary)
            }

            // Notes
            if !encounter.notes.isEmpty {
                Text(encounter.notes)
                    .font(.subheadline)
                    .foregroundStyle(CatchTheme.textPrimary)
            }
        }
        .padding()
        .background(CatchTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}
