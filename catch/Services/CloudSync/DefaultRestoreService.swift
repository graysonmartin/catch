import Foundation
import Observation
import SwiftData
import os
import CatchCore

@Observable
@MainActor
final class DefaultRestoreService: RestoreService {
    private(set) var isRestoring = false

    private let catRepository: any CatRepository
    private let encounterRepository: any EncounterRepository
    private let logger = Logger(subsystem: "com.graysonmartin.catch", category: "Restore")

    init(
        catRepository: any CatRepository,
        encounterRepository: any EncounterRepository
    ) {
        self.catRepository = catRepository
        self.encounterRepository = encounterRepository
    }

    func restoreIfNeeded(ownerID: String) async throws -> RestoreResult {
        isRestoring = true
        defer { isRestoring = false }

        let (restoredCats, restoredEncounters) = try await fetchAndMap(ownerID: ownerID)
        return RestoreResult(
            catsRestored: restoredCats.count,
            encountersRestored: restoredEncounters.count
        )
    }

    /// Fetches the user's data and inserts it into the local SwiftData store.
    func insertRestoredData(
        ownerID: String,
        into context: ModelContext
    ) async throws -> RestoreResult {
        isRestoring = true
        defer { isRestoring = false }

        let (restoredCats, restoredEncounters) = try await fetchAndMap(ownerID: ownerID)

        guard !restoredCats.isEmpty else {
            return RestoreResult(catsRestored: 0, encountersRestored: 0)
        }

        var catLookup: [String: Cat] = [:]

        for restored in restoredCats {
            let cat = Cat(
                name: restored.name,
                breed: restored.breed.isEmpty ? nil : restored.breed,
                estimatedAge: restored.estimatedAge,
                location: restored.location,
                notes: restored.notes,
                isOwned: restored.isOwned,
                photos: restored.photos
            )
            cat.createdAt = restored.createdAt
            cat.cloudKitRecordName = restored.cloudKitRecordName
            context.insert(cat)
            catLookup[restored.cloudKitRecordName] = cat
        }

        var encounterCount = 0
        for restored in restoredEncounters {
            guard let parentCat = catLookup[restored.catRecordName] else {
                logger.warning("skipping encounter \(restored.cloudKitRecordName) — no matching cat for \(restored.catRecordName)")
                continue
            }

            let encounter = Encounter(
                date: restored.date,
                location: restored.location,
                notes: restored.notes,
                cat: parentCat,
                photos: restored.photos
            )
            encounter.cloudKitRecordName = restored.cloudKitRecordName
            context.insert(encounter)
            encounterCount += 1
        }

        try context.save()
        logger.info("restored \(restoredCats.count) cats and \(encounterCount) encounters to local store")

        return RestoreResult(
            catsRestored: restoredCats.count,
            encountersRestored: encounterCount
        )
    }

    // MARK: - Private

    private func fetchAndMap(
        ownerID: String
    ) async throws -> (
        cats: [RestoreMapper.RestoredCat],
        encounters: [RestoreMapper.RestoredEncounter]
    ) {
        async let cloudCats = catRepository.fetchAll(ownerID: ownerID)
        async let cloudEncounters = encounterRepository.fetchAll(ownerID: ownerID)

        let (fetchedCats, fetchedEncounters) = try await (cloudCats, cloudEncounters)

        guard !fetchedCats.isEmpty else {
            logger.info("no cloud data found for owner \(ownerID, privacy: .private) — nothing to restore")
            return ([], [])
        }

        logger.info("found \(fetchedCats.count) cats and \(fetchedEncounters.count) encounters to restore")

        return RestoreMapper.mapAll(
            cats: fetchedCats,
            encounters: fetchedEncounters
        )
    }
}
