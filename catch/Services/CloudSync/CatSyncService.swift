import Foundation

@MainActor
protocol CatSyncService: Observable, Sendable {
    var isSyncing: Bool { get }

    func syncNewCat(_ cat: Cat, firstEncounter: Encounter) async
    func syncCatUpdate(_ cat: Cat) async
    func deleteCat(recordName: String) async throws
}
