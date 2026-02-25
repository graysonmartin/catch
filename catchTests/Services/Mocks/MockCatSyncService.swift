import Foundation
import Observation

@Observable
@MainActor
final class MockCatSyncService: CatSyncService {
    private(set) var isSyncing = false

    private(set) var syncNewCatCalls: [(cat: Cat, encounter: Encounter)] = []
    private(set) var syncCatUpdateCalls: [Cat] = []
    private(set) var deleteCatCalls: [String] = []

    var deleteCatError: (any Error)?

    func syncNewCat(_ cat: Cat, firstEncounter: Encounter) async {
        syncNewCatCalls.append((cat, firstEncounter))
    }

    func syncCatUpdate(_ cat: Cat) async {
        syncCatUpdateCalls.append(cat)
    }

    func deleteCat(recordName: String) async throws {
        deleteCatCalls.append(recordName)
        if let error = deleteCatError { throw error }
    }

    func reset() {
        syncNewCatCalls = []
        syncCatUpdateCalls = []
        deleteCatCalls = []
        deleteCatError = nil
    }
}
