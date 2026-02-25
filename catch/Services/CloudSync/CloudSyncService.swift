import Foundation

@MainActor
protocol CloudSyncService: Observable, Sendable {
    var isSyncing: Bool { get }

    func syncNewCat(_ cat: Cat, firstEncounter: Encounter) async
    func syncCatUpdate(_ cat: Cat) async
    func syncNewEncounter(_ encounter: Encounter, for cat: Cat) async
    func syncEncounterUpdate(_ encounter: Encounter) async
    func deleteCat(recordName: String) async throws
    func deleteEncounter(recordName: String) async throws
}
