import Foundation

@MainActor
protocol EncounterRepository: Observable, Sendable {
    func save(_ payload: EncounterSyncPayload, ownerID: String) async throws -> String
    func delete(recordName: String) async throws
    func fetchAll(ownerID: String) async throws -> [CloudEncounter]
}
