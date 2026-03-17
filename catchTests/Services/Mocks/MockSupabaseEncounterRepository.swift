import Foundation
import CatchCore

@MainActor
final class MockSupabaseEncounterRepository: SupabaseEncounterRepository {
    private(set) var fetchEncounterCalls: [String] = []
    private(set) var fetchEncountersByOwnerCalls: [String] = []
    private(set) var fetchEncountersByCatCalls: [String] = []
    private(set) var insertEncounterCalls: [SupabaseEncounterInsertPayload] = []
    private(set) var updateEncounterCalls: [(id: String, payload: SupabaseEncounterUpdatePayload)] = []
    private(set) var deleteEncounterCalls: [String] = []
    private(set) var fetchEncounterFeedCalls: [(ownerID: String, limit: Int, cursor: String?)] = []

    var fetchEncounterResult: SupabaseEncounter?
    var fetchEncountersResult: [SupabaseEncounter] = []
    var insertEncounterResult: SupabaseEncounter?
    var updateEncounterResult: SupabaseEncounter?
    var fetchEncounterFeedResult: [SupabaseEncounterFeedRow] = []
    var fetchEncounterFeedResultsByCursor: [String?: [SupabaseEncounterFeedRow]] = [:]
    var errorToThrow: (any Error)?

    func fetchEncounter(id: String) async throws -> SupabaseEncounter? {
        fetchEncounterCalls.append(id)
        if let error = errorToThrow { throw error }
        return fetchEncounterResult
    }

    func fetchEncounters(ownerID: String) async throws -> [SupabaseEncounter] {
        fetchEncountersByOwnerCalls.append(ownerID)
        if let error = errorToThrow { throw error }
        return fetchEncountersResult
    }

    func fetchEncounters(catID: String) async throws -> [SupabaseEncounter] {
        fetchEncountersByCatCalls.append(catID)
        if let error = errorToThrow { throw error }
        return fetchEncountersResult
    }

    func insertEncounter(_ payload: SupabaseEncounterInsertPayload) async throws -> SupabaseEncounter {
        insertEncounterCalls.append(payload)
        if let error = errorToThrow { throw error }
        guard let result = insertEncounterResult else {
            throw NSError(domain: "Mock", code: 0)
        }
        return result
    }

    func updateEncounter(id: String, _ payload: SupabaseEncounterUpdatePayload) async throws -> SupabaseEncounter {
        updateEncounterCalls.append((id, payload))
        if let error = errorToThrow { throw error }
        guard let result = updateEncounterResult else {
            throw NSError(domain: "Mock", code: 0)
        }
        return result
    }

    func deleteEncounter(id: String) async throws {
        deleteEncounterCalls.append(id)
        if let error = errorToThrow { throw error }
    }

    func fetchEncounterFeed(
        ownerID: String,
        limit: Int,
        cursor: String?
    ) async throws -> [SupabaseEncounterFeedRow] {
        fetchEncounterFeedCalls.append((ownerID, limit, cursor))
        if let error = errorToThrow { throw error }
        if let cursorResult = fetchEncounterFeedResultsByCursor[cursor] {
            return cursorResult
        }
        return fetchEncounterFeedResult
    }

    func reset() {
        fetchEncounterCalls = []
        fetchEncountersByOwnerCalls = []
        fetchEncountersByCatCalls = []
        insertEncounterCalls = []
        updateEncounterCalls = []
        deleteEncounterCalls = []
        fetchEncounterFeedCalls = []
        fetchEncounterResult = nil
        fetchEncountersResult = []
        insertEncounterResult = nil
        updateEncounterResult = nil
        fetchEncounterFeedResult = []
        fetchEncounterFeedResultsByCursor = [:]
        errorToThrow = nil
    }
}
