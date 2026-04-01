import Foundation
import CatchCore

@MainActor
final class MockSupabaseCatRepository: SupabaseCatRepository {
    private(set) var fetchCatCalls: [String] = []
    private(set) var fetchCatsCalls: [String] = []
    private(set) var fetchCatCountsCalls: [[String]] = []
    private(set) var insertCatCalls: [SupabaseCatInsertPayload] = []
    private(set) var updateCatCalls: [(id: String, payload: SupabaseCatUpdatePayload)] = []
    private(set) var deleteCatCalls: [String] = []

    var fetchCatResult: SupabaseCat?
    var fetchCatsResult: [SupabaseCat] = []
    var fetchCatCountsResult: [String: Int] = [:]
    var insertCatResult: SupabaseCat?
    var updateCatResult: SupabaseCat?
    var errorToThrow: (any Error)?

    func fetchCat(id: String) async throws -> SupabaseCat? {
        fetchCatCalls.append(id)
        if let error = errorToThrow { throw error }
        return fetchCatResult
    }

    func fetchCats(ownerID: String) async throws -> [SupabaseCat] {
        fetchCatsCalls.append(ownerID)
        if let error = errorToThrow { throw error }
        return fetchCatsResult
    }

    func fetchCatCounts(ownerIDs: [String]) async throws -> [String: Int] {
        fetchCatCountsCalls.append(ownerIDs)
        if let error = errorToThrow { throw error }
        return fetchCatCountsResult
    }

    func insertCat(_ payload: SupabaseCatInsertPayload) async throws -> SupabaseCat {
        insertCatCalls.append(payload)
        if let error = errorToThrow { throw error }
        guard let result = insertCatResult else {
            throw NSError(domain: "Mock", code: 0)
        }
        return result
    }

    func updateCat(id: String, _ payload: SupabaseCatUpdatePayload) async throws -> SupabaseCat {
        updateCatCalls.append((id, payload))
        if let error = errorToThrow { throw error }
        guard let result = updateCatResult else {
            throw NSError(domain: "Mock", code: 0)
        }
        return result
    }

    func deleteCat(id: String) async throws {
        deleteCatCalls.append(id)
        if let error = errorToThrow { throw error }
    }

    func reset() {
        fetchCatCalls = []
        fetchCatsCalls = []
        fetchCatCountsCalls = []
        insertCatCalls = []
        updateCatCalls = []
        deleteCatCalls = []
        fetchCatResult = nil
        fetchCatsResult = []
        fetchCatCountsResult = [:]
        insertCatResult = nil
        updateCatResult = nil
        errorToThrow = nil
    }
}
