import Foundation
import Observation
@testable import CatchCore

@Observable
@MainActor
final class MockSupabaseEncounterRepository: SupabaseEncounterRepository {
    private(set) var fetchEncounterCalls: [String] = []
    private(set) var fetchEncountersByOwnerCalls: [String] = []
    private(set) var fetchEncountersByCatCalls: [String] = []
    private(set) var insertEncounterCalls: [SupabaseEncounterInsertPayload] = []
    private(set) var updateEncounterCalls: [(id: String, payload: SupabaseEncounterUpdatePayload)] = []
    private(set) var deleteEncounterCalls: [String] = []

    var fetchEncounterResult: SupabaseEncounter?
    var fetchEncountersResult: [SupabaseEncounter] = []
    var insertEncounterResult: SupabaseEncounter?
    var updateEncounterResult: SupabaseEncounter?
    var errorToThrow: (any Error)?

    func fetchEncounter(id: String) async throws -> SupabaseEncounter? {
        fetchEncounterCalls.append(id)
        if let error = errorToThrow { throw error }
        return fetchEncounterResult
    }

    func fetchEncounters(ownerID: String) async throws -> [SupabaseEncounter] {
        fetchEncountersByOwnerCalls.append(ownerID)
        if let error = errorToThrow { throw error }
        return fetchEncountersResult
    }

    func fetchEncounters(catID: String) async throws -> [SupabaseEncounter] {
        fetchEncountersByCatCalls.append(catID)
        if let error = errorToThrow { throw error }
        return fetchEncountersResult
    }

    func insertEncounter(_ payload: SupabaseEncounterInsertPayload) async throws -> SupabaseEncounter {
        insertEncounterCalls.append(payload)
        if let error = errorToThrow { throw error }
        guard let result = insertEncounterResult else {
            throw NSError(domain: "MockSupabaseEncounterRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "no stubbed insert result"])
        }
        return result
    }

    func updateEncounter(
        id: String,
        _ payload: SupabaseEncounterUpdatePayload
    ) async throws -> SupabaseEncounter {
        updateEncounterCalls.append((id, payload))
        if let error = errorToThrow { throw error }
        guard let result = updateEncounterResult else {
            throw NSError(domain: "MockSupabaseEncounterRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "no stubbed update result"])
        }
        return result
    }

    func deleteEncounter(id: String) async throws {
        deleteEncounterCalls.append(id)
        if let error = errorToThrow { throw error }
    }

    func reset() {
        fetchEncounterCalls = []
        fetchEncountersByOwnerCalls = []
        fetchEncountersByCatCalls = []
        insertEncounterCalls = []
        updateEncounterCalls = []
        deleteEncounterCalls = []
        fetchEncounterResult = nil
        fetchEncountersResult = []
        insertEncounterResult = nil
        updateEncounterResult = nil
        errorToThrow = nil
    }
}

// MARK: - SupabaseEncounter Fixture

extension SupabaseEncounter {
    static func fixture(
        id: UUID = UUID(),
        ownerID: UUID = UUID(),
        catID: UUID = UUID(),
        date: Date = Date(),
        locationName: String? = "park",
        locationLat: Double? = 37.7749,
        locationLng: Double? = -122.4194,
        notes: String? = nil,
        photoUrls: [String] = [],
        likeCount: Int = 0,
        commentCount: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) -> SupabaseEncounter {
        SupabaseEncounter(
            id: id,
            ownerID: ownerID,
            catID: catID,
            date: date,
            locationName: locationName,
            locationLat: locationLat,
            locationLng: locationLng,
            notes: notes,
            photoUrls: photoUrls,
            likeCount: likeCount,
            commentCount: commentCount,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
