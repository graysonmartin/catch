import Foundation
import CatchCore

final class DefaultBreedLogService: BreedLogService {

    func buildBreedLog(from cats: [Cat]) -> [BreedLogEntry] {
        let catsByBreed = groupCatsByBreed(cats)

        return BreedCatalog.allBreeds.map { entry in
            let matchingCats = catsByBreed[entry.id] ?? []
            let firstDate = matchingCats
                .map(\.createdAt)
                .min()

            return BreedLogEntry(
                catalogEntry: entry,
                isDiscovered: !matchingCats.isEmpty,
                catCount: matchingCats.count,
                firstDiscoveredDate: firstDate,
                previewPhotoData: nil
            )
        }
    }

    func buildBreedLog(from cloudCats: [CloudCat]) -> [BreedLogEntry] {
        let catsByBreed = groupCloudCatsByBreed(cloudCats)

        return BreedCatalog.allBreeds.map { entry in
            let matchingCats = catsByBreed[entry.id] ?? []
            let firstDate = matchingCats
                .map(\.createdAt)
                .min()
            let previewPhoto = matchingCats
                .first(where: { !$0.photos.isEmpty })?
                .photos.first

            return BreedLogEntry(
                catalogEntry: entry,
                isDiscovered: !matchingCats.isEmpty,
                catCount: matchingCats.count,
                firstDiscoveredDate: firstDate,
                previewPhotoData: previewPhoto
            )
        }
    }

    func catsForBreed(_ breedName: String, from cats: [Cat]) -> [Cat] {
        cats.filter { $0.breed == breedName }
            .sorted { $0.createdAt < $1.createdAt }
    }

    // MARK: - Private

    private func groupCatsByBreed(_ cats: [Cat]) -> [String: [Cat]] {
        var groups: [String: [Cat]] = [:]
        for cat in cats {
            guard let breed = cat.breed, BreedCatalog.contains(breed) else { continue }
            groups[breed, default: []].append(cat)
        }
        return groups
    }

    private func groupCloudCatsByBreed(_ cats: [CloudCat]) -> [String: [CloudCat]] {
        var groups: [String: [CloudCat]] = [:]
        for cat in cats {
            guard BreedCatalog.contains(cat.breed) else { continue }
            groups[cat.breed, default: []].append(cat)
        }
        return groups
    }
}
