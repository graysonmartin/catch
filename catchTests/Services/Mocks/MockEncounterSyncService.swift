import Foundation
import Observation
import CatchCore

@Observable
@MainActor
final class MockEncounterSyncService: EncounterSyncService {
    private(set) var isSyncing = false

    private(set) var syncNewEncounterCalls: [(encounter: Encounter, cat: Cat)] = []
    private(set) var syncEncounterUpdateCalls: [Encounter] = []
    private(set) var deleteEncounterCalls: [String] = []

    var syncNewEncounterError: (any Error)?
    var syncEncounterUpdateError: (any Error)?
    var deleteEncounterError: (any Error)?

    func syncNewEncounter(_ encounter: Encounter, for cat: Cat) async throws {
        syncNewEncounterCalls.append((encounter, cat))
        if let error = syncNewEncounterError { throw error }
    }

    func syncEncounterUpdate(_ encounter: Encounter) async throws {
        syncEncounterUpdateCalls.append(encounter)
        if let error = syncEncounterUpdateError { throw error }
    }

    func deleteEncounter(recordName: String) async throws {
        deleteEncounterCalls.append(recordName)
        if let error = deleteEncounterError { throw error }
    }

    func reset() {
        syncNewEncounterCalls = []
        syncEncounterUpdateCalls = []
        deleteEncounterCalls = []
        syncNewEncounterError = nil
        syncEncounterUpdateError = nil
        deleteEncounterError = nil
    }
}
