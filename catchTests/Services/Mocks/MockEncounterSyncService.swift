import Foundation
import Observation

@Observable
@MainActor
final class MockEncounterSyncService: EncounterSyncService {
    private(set) var isSyncing = false

    private(set) var syncNewEncounterCalls: [(encounter: Encounter, cat: Cat)] = []
    private(set) var syncEncounterUpdateCalls: [Encounter] = []
    private(set) var deleteEncounterCalls: [String] = []

    var deleteEncounterError: (any Error)?

    func syncNewEncounter(_ encounter: Encounter, for cat: Cat) async {
        syncNewEncounterCalls.append((encounter, cat))
    }

    func syncEncounterUpdate(_ encounter: Encounter) async {
        syncEncounterUpdateCalls.append(encounter)
    }

    func deleteEncounter(recordName: String) async throws {
        deleteEncounterCalls.append(recordName)
        if let error = deleteEncounterError { throw error }
    }

    func reset() {
        syncNewEncounterCalls = []
        syncEncounterUpdateCalls = []
        deleteEncounterCalls = []
        deleteEncounterError = nil
    }
}
