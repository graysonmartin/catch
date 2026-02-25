import Foundation
import Observation

@Observable
@MainActor
final class MockEncounterRepository: EncounterRepository {
    private(set) var saveCalls: [(payload: EncounterSyncPayload, ownerID: String)] = []
    private(set) var deleteCalls: [String] = []
    private(set) var fetchAllCalls: [String] = []

    var saveResult: Result<String, any Error> = .success("mock-enc-record")
    var deleteError: (any Error)?
    var fetchAllResult: [CloudEncounter] = []
    var fetchAllError: (any Error)?

    func save(_ payload: EncounterSyncPayload, ownerID: String) async throws -> String {
        saveCalls.append((payload, ownerID))
        return try saveResult.get()
    }

    func delete(recordName: String) async throws {
        deleteCalls.append(recordName)
        if let error = deleteError { throw error }
    }

    func fetchAll(ownerID: String) async throws -> [CloudEncounter] {
        fetchAllCalls.append(ownerID)
        if let error = fetchAllError { throw error }
        return fetchAllResult
    }

    func reset() {
        saveCalls = []
        deleteCalls = []
        fetchAllCalls = []
        saveResult = .success("mock-enc-record")
        deleteError = nil
        fetchAllResult = []
        fetchAllError = nil
    }
}
