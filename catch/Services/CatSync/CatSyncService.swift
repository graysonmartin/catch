import Foundation

@MainActor
protocol CatSyncService: Observable, Sendable {
    func saveCat(_ payload: CatSyncPayload, ownerID: String) async throws -> String
    func saveEncounter(_ payload: EncounterSyncPayload, ownerID: String) async throws -> String
    func deleteCat(recordName: String) async throws
    func deleteEncounter(recordName: String) async throws
    func fetchCats(ownerID: String) async throws -> [CloudCat]
    func fetchEncounters(ownerID: String) async throws -> [CloudEncounter]
}
