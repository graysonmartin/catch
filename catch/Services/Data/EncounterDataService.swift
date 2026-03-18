import Foundation
import Observation
import os
import CatchCore

/// Service layer for encounter CRUD operations against Supabase.
@Observable
@MainActor
final class EncounterDataService {
    private let encounterRepository: any SupabaseEncounterRepository
    private let assetService: any SupabaseAssetService
    private let getUserID: @Sendable () -> String?
    private let logger = Logger(subsystem: "com.graysonmartin.catch", category: "EncounterDataService")

    init(
        encounterRepository: any SupabaseEncounterRepository,
        assetService: any SupabaseAssetService,
        getUserID: @escaping @Sendable () -> String?
    ) {
        self.encounterRepository = encounterRepository
        self.assetService = assetService
        self.getUserID = getUserID
    }

    // MARK: - Create

    func createEncounter(
        catID: UUID,
        date: Date,
        location: Location,
        notes: String,
        photos: [Data]
    ) async throws -> Encounter {
        guard let userID = getUserID() else {
            throw CatDataServiceError.notSignedIn
        }

        let photoUrls = try await uploadPhotos(photos, ownerID: userID)

        let encounter = Encounter(
            id: UUID(),
            date: date,
            location: location,
            notes: notes,
            catID: catID,
            ownerID: UUID(uuidString: userID) ?? UUID(),
            photoUrls: photoUrls
        )

        let inserted = try await encounterRepository.insertEncounter(
            encounter.toInsertPayload(ownerID: userID)
        )
        return Encounter(supabase: inserted)
    }

    // MARK: - Update

    func updateEncounter(_ encounter: Encounter, photos: [PhotoItem]) async throws -> Encounter {
        guard let userID = getUserID() else {
            throw CatDataServiceError.notSignedIn
        }

        var updated = encounter

        // Upload local photos and resolve all items to final URLs in order.
        let localPhotos = photos.localData
        var uploadedUrls: [String] = []
        if !localPhotos.isEmpty {
            uploadedUrls = try await uploadPhotos(localPhotos, ownerID: userID)
        }

        var uploadIndex = 0
        updated.photoUrls = photos.map { item in
            switch item.content {
            case .remote(let url):
                return url
            case .local:
                defer { uploadIndex += 1 }
                return uploadedUrls[uploadIndex]
            }
        }

        let result = try await encounterRepository.updateEncounter(
            id: encounter.id.uuidString,
            updated.toUpdatePayload()
        )
        return Encounter(supabase: result)
    }

    // MARK: - Delete

    func deleteEncounter(id: UUID) async throws {
        try await encounterRepository.deleteEncounter(id: id.uuidString)
    }

    // MARK: - Photos

    private func uploadPhotos(_ photos: [Data], ownerID: String) async throws -> [String] {
        guard !photos.isEmpty else { return [] }
        return try await assetService.uploadPhotos(photos, bucket: .encounterPhotos, ownerID: ownerID)
    }
}
