import Foundation
import Observation
import os

/// Adapts `SupabaseCatRepository` to conform to the existing `CatRepository` protocol,
/// enabling drop-in replacement of the CloudKit-backed implementation.
@Observable
@MainActor
public final class SupabaseCatRepositoryAdapter: CatRepository, @unchecked Sendable {
    private let repository: any SupabaseCatRepository
    private let logger = Logger(subsystem: "com.graysonmartin.catch", category: "SupabaseCatRepositoryAdapter")

    public init(repository: any SupabaseCatRepository) {
        self.repository = repository
    }

    // MARK: - CatRepository

    public func save(_ payload: CatSyncPayload, ownerID: String) async throws -> String {
        if let existingID = payload.recordName {
            let updatePayload = SupabaseCatMapper.updatePayload(from: payload)
            let updated = try await repository.updateCat(id: existingID, updatePayload)
            return updated.id.uuidString
        } else {
            let recordName = UUID().uuidString
            let insertPayload = SupabaseCatMapper.insertPayload(
                from: payload,
                ownerID: ownerID,
                recordName: recordName
            )
            let inserted = try await repository.insertCat(insertPayload)
            return inserted.id.uuidString
        }
    }

    public func delete(recordName: String) async throws {
        try await repository.deleteCat(id: recordName)
    }

    public func fetchAll(ownerID: String) async throws -> [CloudCat] {
        let cats = try await repository.fetchCats(ownerID: ownerID)
        return cats.map { SupabaseCatMapper.toCloudCat($0) }
    }
}
