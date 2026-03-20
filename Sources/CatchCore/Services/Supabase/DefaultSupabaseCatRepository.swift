import Foundation
import Supabase

@MainActor
public final class DefaultSupabaseCatRepository: SupabaseCatRepository, @unchecked Sendable {
    private let clientProvider: any SupabaseClientProviding
    private static let tableName = "cats"

    public init(clientProvider: any SupabaseClientProviding) {
        self.clientProvider = clientProvider
    }

    // MARK: - SupabaseCatRepository

    public func fetchCat(id: String) async throws -> SupabaseCat? {
        let response: [SupabaseCat] = try await clientProvider.client
            .from(Self.tableName)
            .select()
            .eq("id", value: id)
            .limit(1)
            .execute()
            .value
        return response.first
    }

    public func fetchCatCounts(ownerIDs: [String]) async throws -> [String: Int] {
        guard !ownerIDs.isEmpty else { return [:] }

        let rows: [CatOwnerRow] = try await clientProvider.client
            .from(Self.tableName)
            .select("owner_id")
            .in("owner_id", values: ownerIDs)
            .execute()
            .value

        var counts: [String: Int] = [:]
        for row in rows {
            let key = row.ownerID.uuidString.lowercased()
            counts[key, default: 0] += 1
        }
        return counts
    }

    public func fetchCats(ownerID: String) async throws -> [SupabaseCat] {
        try await clientProvider.client
            .from(Self.tableName)
            .select()
            .eq("owner_id", value: ownerID)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    public func insertCat(_ payload: SupabaseCatInsertPayload) async throws -> SupabaseCat {
        try await clientProvider.client
            .from(Self.tableName)
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
    }

    public func updateCat(id: String, _ payload: SupabaseCatUpdatePayload) async throws -> SupabaseCat {
        try await clientProvider.client
            .from(Self.tableName)
            .update(payload)
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value
    }

    public func deleteCat(id: String) async throws {
        try await clientProvider.client
            .from(Self.tableName)
            .delete()
            .eq("id", value: id)
            .execute()
    }
}

// MARK: - Lightweight Row Types

/// Minimal row for batch cat count queries — only decodes the owner_id column.
private struct CatOwnerRow: Decodable {
    let ownerID: UUID

    private enum CodingKeys: String, CodingKey {
        case ownerID = "owner_id"
    }
}
