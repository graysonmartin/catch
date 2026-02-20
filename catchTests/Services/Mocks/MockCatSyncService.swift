import Foundation
import Observation

@Observable
@MainActor
final class MockCatSyncService: CatSyncService {
    private(set) var saveCatCalls: [(payload: CatSyncPayload, ownerID: String)] = []
    private(set) var saveEncounterCalls: [(payload: EncounterSyncPayload, ownerID: String)] = []
    private(set) var deleteCatCalls: [String] = []
    private(set) var deleteEncounterCalls: [String] = []
    private(set) var fetchCatsCalls: [String] = []
    private(set) var fetchEncountersCalls: [String] = []

    var saveCatResult: Result<String, any Error> = .success("mock-cat-record")
    var saveEncounterResult: Result<String, any Error> = .success("mock-enc-record")
    var deleteCatError: (any Error)?
    var deleteEncounterError: (any Error)?
    var fetchCatsResult: [CloudCat] = []
    var fetchEncountersResult: [CloudEncounter] = []
    var fetchCatsError: (any Error)?
    var fetchEncountersError: (any Error)?

    func saveCat(_ payload: CatSyncPayload, ownerID: String) async throws -> String {
        saveCatCalls.append((payload, ownerID))
        return try saveCatResult.get()
    }

    func saveEncounter(_ payload: EncounterSyncPayload, ownerID: String) async throws -> String {
        saveEncounterCalls.append((payload, ownerID))
        return try saveEncounterResult.get()
    }

    func deleteCat(recordName: String) async throws {
        deleteCatCalls.append(recordName)
        if let error = deleteCatError { throw error }
    }

    func deleteEncounter(recordName: String) async throws {
        deleteEncounterCalls.append(recordName)
        if let error = deleteEncounterError { throw error }
    }

    func fetchCats(ownerID: String) async throws -> [CloudCat] {
        fetchCatsCalls.append(ownerID)
        if let error = fetchCatsError { throw error }
        return fetchCatsResult
    }

    func fetchEncounters(ownerID: String) async throws -> [CloudEncounter] {
        fetchEncountersCalls.append(ownerID)
        if let error = fetchEncountersError { throw error }
        return fetchEncountersResult
    }

    func reset() {
        saveCatCalls = []
        saveEncounterCalls = []
        deleteCatCalls = []
        deleteEncounterCalls = []
        fetchCatsCalls = []
        fetchEncountersCalls = []
        saveCatResult = .success("mock-cat-record")
        saveEncounterResult = .success("mock-enc-record")
        deleteCatError = nil
        deleteEncounterError = nil
        fetchCatsResult = []
        fetchEncountersResult = []
        fetchCatsError = nil
        fetchEncountersError = nil
    }
}
