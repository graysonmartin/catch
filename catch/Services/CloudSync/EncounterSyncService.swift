import Foundation

@MainActor
protocol EncounterSyncService: Observable, Sendable {
    var isSyncing: Bool { get }

    func syncNewEncounter(_ encounter: Encounter, for cat: Cat) async
    func syncEncounterUpdate(_ encounter: Encounter) async
    func deleteEncounter(recordName: String) async throws
}
