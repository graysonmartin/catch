import Foundation
import Observation
import os

/// Adapts `SupabaseEncounterRepository` to conform to the existing `EncounterRepository` protocol,
/// enabling drop-in replacement of the CloudKit-backed implementation.
@Observable
@MainActor
public final class SupabaseEncounterRepositoryAdapter: EncounterRepository, @unchecked Sendable {
    private let repository: any SupabaseEncounterRepository
    private let logger = Logger(
        subsystem: "com.graysonmartin.catch",
        category: "SupabaseEncounterRepositoryAdapter"
    )

    public init(repository: any SupabaseEncounterRepository) {
        self.repository = repository
    }

    // MARK: - EncounterRepository

    public func save(_ payload: EncounterSyncPayload, ownerID: String) async throws -> String {
        if let existingID = payload.recordName {
            let updatePayload = SupabaseEncounterMapper.updatePayload(from: payload)
            let updated = try await repository.updateEncounter(id: existingID, updatePayload)
            return updated.id.uuidString.lowercased()
        } else {
            let recordName = UUID().uuidString.lowercased()
            let insertPayload = SupabaseEncounterMapper.insertPayload(
                from: payload,
                ownerID: ownerID,
                recordName: recordName
            )
            let inserted = try await repository.insertEncounter(insertPayload)
            return inserted.id.uuidString.lowercased()
        }
    }

    public func delete(recordName: String) async throws {
        try await repository.deleteEncounter(id: recordName)
    }

    public func fetchAll(ownerID: String) async throws -> [CloudEncounter] {
        let encounters = try await repository.fetchEncounters(ownerID: ownerID)
        return encounters.map { SupabaseEncounterMapper.toCloudEncounter($0) }
    }
}
