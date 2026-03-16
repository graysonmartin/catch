import Foundation

/// Data-access layer for cats stored in Supabase.
@MainActor
public protocol SupabaseCatRepository: Sendable {
    func fetchCat(id: String) async throws -> SupabaseCat?
    func fetchCats(ownerID: String) async throws -> [SupabaseCat]
    func insertCat(_ payload: SupabaseCatInsertPayload) async throws -> SupabaseCat
    func updateCat(id: String, _ payload: SupabaseCatUpdatePayload) async throws -> SupabaseCat
    func deleteCat(id: String) async throws
}
