import Foundation

@MainActor
public protocol CatSyncService: Observable, Sendable {
    associatedtype CatModel
    associatedtype EncounterModel

    var isSyncing: Bool { get }

    func syncNewCat(_ cat: CatModel, firstEncounter: EncounterModel) async
    func syncCatUpdate(_ cat: CatModel) async
    func deleteCat(recordName: String) async throws
}
