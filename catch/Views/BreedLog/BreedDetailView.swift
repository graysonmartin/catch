import SwiftUI
import CatchCore

struct BreedDetailView: View {
    let entry: BreedLogEntry
    let cats: [Cat]

    var body: some View {
        ScrollView {
            VStack(spacing: CatchSpacing.space20) {
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
        VStack(spacing: CatchSpacing.space12) {
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
           let uiImage = ImageDownsampler.shared.downsample(data: photoData, to: CGSize(width: 160, height: 160)) {
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
        HStack(spacing: CatchSpacing.space16) {
            statCard(value: "\(entry.catCount)", label: CatchStrings.BreedLog.catsFound)
            if let date = entry.firstDiscoveredDate {
                statCard(value: date.formatted(.dateTime.month(.abbreviated).day()), label: CatchStrings.BreedLog.firstSeen)
            }
        }
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: CatchSpacing.space4) {
            Text(value)
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(CatchTheme.primary)
            Text(label)
                .font(.caption)
                .foregroundStyle(CatchTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, CatchSpacing.space12)
        .background(CatchTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusSmall))
        .shadow(color: .black.opacity(CatchTheme.cardShadowOpacity), radius: CatchTheme.cardShadowRadius, y: CatchTheme.cardShadowY)
    }

    // MARK: - Fun Fact

    private var funFactSection: some View {
        VStack(alignment: .leading, spacing: CatchSpacing.space8) {
            Text(CatchStrings.BreedLog.funFact)
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
        VStack(alignment: .leading, spacing: CatchSpacing.space12) {
            Text(CatchStrings.BreedLog.yourBreedCats(entry.catalogEntry.displayName.lowercased()))
                .font(.caption.weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(CatchTheme.textSecondary)

            ForEach(cats) { cat in
                HStack(spacing: CatchSpacing.space12) {
                    CatPhotoView(photoData: nil, photoUrl: cat.photoUrls.first, size: 44)

                    VStack(alignment: .leading, spacing: CatchSpacing.space2) {
                        Text(cat.displayName)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(cat.isUnnamed ? CatchTheme.textSecondary : CatchTheme.textPrimary)
                        Text(CatchStrings.Common.encounterCount(cat.encounters.count))
                            .font(.caption)
                            .foregroundStyle(CatchTheme.textSecondary)
                    }

                    Spacer()
                }
                .padding(CatchSpacing.space10)
                .background(CatchTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusTight))
            }
        }
    }
}
