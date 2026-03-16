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
}
