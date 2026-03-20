import Foundation
import Observation
import CatchCore

@Observable
@MainActor
final class MockCatRepository: CatRepository {
    private(set) var saveCalls: [(payload: CatSyncPayload, ownerID: String)] = []
    private(set) var deleteCalls: [String] = []
    private(set) var fetchAllCalls: [String] = []
    private(set) var fetchCatCountsCalls: [[String]] = []

    var saveResult: Result<String, any Error> = .success("mock-cat-record")
    var deleteError: (any Error)?
    var fetchAllResult: [CloudCat] = []
    var fetchAllError: (any Error)?
    var fetchCatCountsResult: [String: Int] = [:]
    var fetchCatCountsError: (any Error)?

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

    func fetchCatCounts(ownerIDs: [String]) async throws -> [String: Int] {
        fetchCatCountsCalls.append(ownerIDs)
        if let error = fetchCatCountsError { throw error }
        return fetchCatCountsResult
    }

    func reset() {
        saveCalls = []
        deleteCalls = []
        fetchAllCalls = []
        fetchCatCountsCalls = []
        saveResult = .success("mock-cat-record")
        deleteError = nil
        fetchAllResult = []
        fetchAllError = nil
        fetchCatCountsResult = [:]
        fetchCatCountsError = nil
    }
}
