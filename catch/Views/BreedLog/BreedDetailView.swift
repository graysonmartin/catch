import SwiftUI

struct BreedDetailView: View {
    let entry: BreedLogEntry
    let cats: [Cat]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                statsSection
                funFactSection
                if !cats.isEmpty {
                    catsSection
                }
            }
            .padding()
        }
        .background(CatchTheme.background)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            headerImage

            Text(entry.catalogEntry.displayName.lowercased())
                .font(.title2.weight(.bold))
                .foregroundStyle(CatchTheme.textPrimary)

            BreedRarityBadge(rarity: entry.catalogEntry.rarity)

            Text(entry.catalogEntry.description)
                .font(.subheadline)
                .foregroundStyle(CatchTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var headerImage: some View {
        if let photoData = entry.previewPhotoData,
           let uiImage = ImageDownsampler.downsample(data: photoData, to: CGSize(width: 160, height: 160)) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadius))
        } else {
            Image(systemName: entry.catalogEntry.icon)
                .font(.system(size: 44))
                .foregroundStyle(entry.catalogEntry.rarity.color)
                .frame(width: 100, height: 100)
                .background(entry.catalogEntry.rarity.color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadius))
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: 16) {
            statCard(value: "\(entry.catCount)", label: "cats found")
            if let date = entry.firstDiscoveredDate {
                statCard(value: date.formatted(.dateTime.month(.abbreviated).day()), label: "first seen")
            }
        }
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(CatchTheme.primary)
            Text(label)
                .font(.caption)
                .foregroundStyle(CatchTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(CatchTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusSmall))
        .shadow(color: .black.opacity(CatchTheme.cardShadowOpacity), radius: CatchTheme.cardShadowRadius, y: CatchTheme.cardShadowY)
    }

    // MARK: - Fun Fact

    private var funFactSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("fun fact")
                .font(.caption.weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(CatchTheme.textSecondary)

            Text(entry.catalogEntry.funFact)
                .font(.subheadline)
                .foregroundStyle(CatchTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(CatchTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusSmall))
        .shadow(color: .black.opacity(CatchTheme.cardShadowOpacity), radius: CatchTheme.cardShadowRadius, y: CatchTheme.cardShadowY)
    }

    // MARK: - Cats List

    private var catsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("your \(entry.catalogEntry.displayName.lowercased()) cats")
                .font(.caption.weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(CatchTheme.textSecondary)

            ForEach(cats) { cat in
                HStack(spacing: 12) {
                    CatPhotoView(photoData: cat.photos.first, size: 44)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(cat.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(CatchTheme.textPrimary)
                        Text("\(cat.encounters.count) encounter\(cat.encounters.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(CatchTheme.textSecondary)
                    }

                    Spacer()
                }
                .padding(10)
                .background(CatchTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusTight))
            }
        }
    }
}
