import Foundation
import Observation

@Observable
@MainActor
final class MockCloudSyncService: CloudSyncService {
    private(set) var isSyncing = false

    private(set) var syncNewCatCalls: [(cat: Cat, encounter: Encounter)] = []
    private(set) var syncCatUpdateCalls: [Cat] = []
    private(set) var syncNewEncounterCalls: [(encounter: Encounter, cat: Cat)] = []
    private(set) var syncEncounterUpdateCalls: [Encounter] = []
    private(set) var deleteCatCalls: [String] = []
    private(set) var deleteEncounterCalls: [String] = []

    var deleteCatError: (any Error)?
    var deleteEncounterError: (any Error)?

    func syncNewCat(_ cat: Cat, firstEncounter: Encounter) async {
        syncNewCatCalls.append((cat, firstEncounter))
    }

    func syncCatUpdate(_ cat: Cat) async {
        syncCatUpdateCalls.append(cat)
    }

    func syncNewEncounter(_ encounter: Encounter, for cat: Cat) async {
        syncNewEncounterCalls.append((encounter, cat))
    }

    func syncEncounterUpdate(_ encounter: Encounter) async {
        syncEncounterUpdateCalls.append(encounter)
    }

    func deleteCat(recordName: String) async throws {
        deleteCatCalls.append(recordName)
        if let error = deleteCatError { throw error }
    }

    func deleteEncounter(recordName: String) async throws {
        deleteEncounterCalls.append(recordName)
        if let error = deleteEncounterError { throw error }
    }

    func reset() {
        syncNewCatCalls = []
        syncCatUpdateCalls = []
        syncNewEncounterCalls = []
        syncEncounterUpdateCalls = []
        deleteCatCalls = []
        deleteEncounterCalls = []
        deleteCatError = nil
        deleteEncounterError = nil
    }
}
