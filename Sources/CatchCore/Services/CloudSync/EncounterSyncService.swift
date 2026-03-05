import Foundation

@MainActor
public protocol EncounterSyncService: Observable, Sendable {
    associatedtype EncounterModel
    associatedtype CatModel

    var isSyncing: Bool { get }

    func syncNewEncounter(_ encounter: EncounterModel, for cat: CatModel) async throws
    func syncEncounterUpdate(_ encounter: EncounterModel) async throws
    func deleteEncounter(recordName: String) async throws
}
