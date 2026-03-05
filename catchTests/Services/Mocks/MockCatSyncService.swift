import Foundation
import Observation
import CatchCore

@Observable
@MainActor
final class MockCatSyncService: CatSyncService {
    private(set) var isSyncing = false

    private(set) var syncNewCatCalls: [(cat: Cat, encounter: Encounter)] = []
    private(set) var syncCatUpdateCalls: [Cat] = []
    private(set) var deleteCatCalls: [String] = []

    var syncNewCatError: (any Error)?
    var syncCatUpdateError: (any Error)?
    var deleteCatError: (any Error)?

    func syncNewCat(_ cat: Cat, firstEncounter: Encounter) async throws {
        syncNewCatCalls.append((cat, firstEncounter))
        if let error = syncNewCatError { throw error }
    }

    func syncCatUpdate(_ cat: Cat) async throws {
        syncCatUpdateCalls.append(cat)
        if let error = syncCatUpdateError { throw error }
    }

    func deleteCat(recordName: String) async throws {
        deleteCatCalls.append(recordName)
        if let error = deleteCatError { throw error }
    }

    func reset() {
        syncNewCatCalls = []
        syncCatUpdateCalls = []
        deleteCatCalls = []
        syncNewCatError = nil
        syncCatUpdateError = nil
        deleteCatError = nil
    }
}
