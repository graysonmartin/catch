import Foundation
@testable import CatchCore

@MainActor
final class MockHiddenEncounterRepository: HiddenEncounterRepository {

    // MARK: - Call Tracking

    var hideEncounterCalls: [(userID: String, encounterID: String)] = []
    var unhideEncounterCalls: [(userID: String, encounterID: String)] = []
    var fetchHiddenCalls: [String] = []

    // MARK: - Stubbed Results

    var hideEncounterError: (any Error)?
    var unhideEncounterError: (any Error)?
    var fetchHiddenResult: Set<String> = []
    var fetchHiddenError: (any Error)?

    // MARK: - Protocol

    func hideEncounter(userID: String, encounterID: String) async throws {
        hideEncounterCalls.append((userID, encounterID))
        if let hideEncounterError { throw hideEncounterError }
    }

    func unhideEncounter(userID: String, encounterID: String) async throws {
        unhideEncounterCalls.append((userID, encounterID))
        if let unhideEncounterError { throw unhideEncounterError }
    }

    func fetchHiddenEncounterIDs(userID: String) async throws -> Set<String> {
        fetchHiddenCalls.append(userID)
        if let fetchHiddenError { throw fetchHiddenError }
        return fetchHiddenResult
    }
}
