import Foundation

/// Data-access layer for encounters stored in Supabase.
@MainActor
public protocol SupabaseEncounterRepository: Sendable {
    func fetchEncounter(id: String) async throws -> SupabaseEncounter?
    func fetchEncounters(ownerID: String) async throws -> [SupabaseEncounter]
    func fetchEncounters(catID: String) async throws -> [SupabaseEncounter]
    func insertEncounter(_ payload: SupabaseEncounterInsertPayload) async throws -> SupabaseEncounter
    func updateEncounter(id: String, _ payload: SupabaseEncounterUpdatePayload) async throws -> SupabaseEncounter
    func deleteEncounter(id: String) async throws

    /// Fetches a page of encounters for the given owner with joined cat data.
    /// Results are ordered by date descending. Uses cursor-based pagination.
    /// - Parameters:
    ///   - ownerID: The user whose encounters to fetch.
    ///   - limit: Maximum number of rows to return.
    ///   - cursor: ISO 8601 date string for cursor-based pagination (exclusive upper bound).
    func fetchEncounterFeed(
        ownerID: String,
        limit: Int,
        cursor: String?
    ) async throws -> [SupabaseEncounterFeedRow]
}
