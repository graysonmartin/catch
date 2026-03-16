import Foundation
import Supabase

@MainActor
public final class DefaultSupabaseEncounterRepository: SupabaseEncounterRepository, @unchecked Sendable {
    private let clientProvider: any SupabaseClientProviding
    private static let tableName = "encounters"

    public init(clientProvider: any SupabaseClientProviding) {
        self.clientProvider = clientProvider
    }

    // MARK: - SupabaseEncounterRepository

    public func fetchEncounter(id: String) async throws -> SupabaseEncounter? {
        let response: [SupabaseEncounter] = try await clientProvider.client
            .from(Self.tableName)
            .select()
            .eq("id", value: id)
            .limit(1)
            .execute()
            .value
        return response.first
    }

    public func fetchEncounters(ownerID: String) async throws -> [SupabaseEncounter] {
        try await clientProvider.client
            .from(Self.tableName)
            .select()
            .eq("owner_id", value: ownerID)
            .order("date", ascending: false)
            .execute()
            .value
    }

    public func fetchEncounters(catID: String) async throws -> [SupabaseEncounter] {
        try await clientProvider.client
            .from(Self.tableName)
            .select()
            .eq("cat_id", value: catID)
            .order("date", ascending: false)
            .execute()
            .value
    }

    public func insertEncounter(_ payload: SupabaseEncounterInsertPayload) async throws -> SupabaseEncounter {
        try await clientProvider.client
            .from(Self.tableName)
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
    }

    public func updateEncounter(
        id: String,
        _ payload: SupabaseEncounterUpdatePayload
    ) async throws -> SupabaseEncounter {
        try await clientProvider.client
            .from(Self.tableName)
            .update(payload)
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value
    }

    public func deleteEncounter(id: String) async throws {
        try await clientProvider.client
            .from(Self.tableName)
            .delete()
            .eq("id", value: id)
            .execute()
    }
}
