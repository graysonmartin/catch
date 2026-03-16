import Foundation
import Observation
import os
import CatchCore

/// Service layer for cat CRUD operations against Supabase.
/// Views depend on this instead of directly using repositories.
@Observable
@MainActor
final class CatDataService {
    private(set) var cats: [Cat] = []
    private(set) var isLoading = false

    private let catRepository: any SupabaseCatRepository
    private let encounterRepository: any SupabaseEncounterRepository
    private let assetService: any SupabaseAssetService
    private let getUserID: @Sendable () -> String?
    private let logger = Logger(subsystem: "com.graysonmartin.catch", category: "CatDataService")

    init(
        catRepository: any SupabaseCatRepository,
        encounterRepository: any SupabaseEncounterRepository,
        assetService: any SupabaseAssetService,
        getUserID: @escaping @Sendable () -> String?
    ) {
        self.catRepository = catRepository
        self.encounterRepository = encounterRepository
        self.assetService = assetService
        self.getUserID = getUserID
    }

    // MARK: - Fetch

    func loadCats() async throws {
        guard let userID = getUserID() else { return }
        isLoading = true
        defer { isLoading = false }

        let supabaseCats = try await catRepository.fetchCats(ownerID: userID)
        let supabaseEncounters = try await encounterRepository.fetchEncounters(ownerID: userID)

        let encountersByCat = Dictionary(grouping: supabaseEncounters) { $0.catID }

        cats = supabaseCats.map { sCat in
            let catEncounters = (encountersByCat[sCat.id] ?? []).map { sEnc in
                Encounter(supabase: sEnc)
            }
            return Cat(supabase: sCat, encounters: catEncounters)
        }
    }

    func fetchCat(id: UUID) async throws -> Cat? {
        guard let sCat = try await catRepository.fetchCat(id: id.uuidString) else {
            return nil
        }
        let sEncounters = try await encounterRepository.fetchEncounters(catID: id.uuidString)
        let encounters = sEncounters.map { Encounter(supabase: $0) }
        return Cat(supabase: sCat, encounters: encounters)
    }

    // MARK: - Create

    func createCat(
        name: String?,
        breed: String?,
        location: Location,
        notes: String,
        isOwned: Bool,
        photos: [Data],
        encounterDate: Date
    ) async throws -> Cat {
        guard let userID = getUserID() else {
            throw CatDataServiceError.notSignedIn
        }

        let catID = UUID()

        // Upload photos
        let photoUrls = try await uploadPhotos(photos, ownerID: userID)

        let cat = Cat(
            id: catID,
            name: name,
            breed: breed,
            location: location,
            notes: notes,
            isOwned: isOwned,
            photoUrls: photoUrls,
            ownerID: UUID(uuidString: userID) ?? UUID(),
            createdAt: Date()
        )

        let insertedCat = try await catRepository.insertCat(cat.toInsertPayload(ownerID: userID))

        // Create first encounter
        let encounter = Encounter(
            id: UUID(),
            date: encounterDate,
            location: location,
            notes: "",
            catID: insertedCat.id,
            ownerID: UUID(uuidString: userID) ?? UUID(),
            photoUrls: photoUrls
        )

        let insertedEncounter = try await encounterRepository.insertEncounter(
            encounter.toInsertPayload(ownerID: userID)
        )

        let result = Cat(supabase: insertedCat, encounters: [Encounter(supabase: insertedEncounter)])
        cats.insert(result, at: 0)
        return result
    }

    // MARK: - Update

    func updateCat(_ cat: Cat, photos: [Data]) async throws -> Cat {
        guard let userID = getUserID() else {
            throw CatDataServiceError.notSignedIn
        }

        var updatedCat = cat

        // Upload any new photos
        if !photos.isEmpty {
            let newUrls = try await uploadPhotos(photos, ownerID: userID)
            updatedCat.photoUrls = newUrls
        }

        let updated = try await catRepository.updateCat(
            id: cat.id.uuidString,
            updatedCat.toUpdatePayload()
        )

        let result = Cat(supabase: updated, encounters: cat.encounters)
        if let idx = cats.firstIndex(where: { $0.id == result.id }) {
            cats[idx] = result
        }
        return result
    }

    // MARK: - Delete

    func deleteCat(_ cat: Cat) async throws {
        try await catRepository.deleteCat(id: cat.id.uuidString)
        cats.removeAll { $0.id == cat.id }
    }

    // MARK: - Photos

    private func uploadPhotos(_ photos: [Data], ownerID: String) async throws -> [String] {
        guard !photos.isEmpty else { return [] }
        return try await assetService.uploadPhotos(photos, bucket: .catPhotos, ownerID: ownerID)
    }
}

enum CatDataServiceError: Error, LocalizedError {
    case notSignedIn

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "You must be signed in to perform this action."
        }
    }
}
