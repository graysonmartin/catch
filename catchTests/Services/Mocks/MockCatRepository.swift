import Foundation
import Observation

@Observable
@MainActor
final class MockCatRepository: CatRepository {
    private(set) var saveCalls: [(payload: CatSyncPayload, ownerID: String)] = []
    private(set) var deleteCalls: [String] = []
    private(set) var fetchAllCalls: [String] = []

    var saveResult: Result<String, any Error> = .success("mock-cat-record")
    var deleteError: (any Error)?
    var fetchAllResult: [CloudCat] = []
    var fetchAllError: (any Error)?

    func save(_ payload: CatSyncPayload, ownerID: String) async throws -> String {
        saveCalls.append((payload, ownerID))
        return try saveResult.get()
    }

    func delete(recordName: String) async throws {
        deleteCalls.append(recordName)
        if let error = deleteError { throw error }
    }

    func fetchAll(ownerID: String) async throws -> [CloudCat] {
        fetchAllCalls.append(ownerID)
        if let error = fetchAllError { throw error }
        return fetchAllResult
    }

    func reset() {
        saveCalls = []
        deleteCalls = []
        fetchAllCalls = []
        saveResult = .success("mock-cat-record")
        deleteError = nil
        fetchAllResult = []
        fetchAllError = nil
    }
}
