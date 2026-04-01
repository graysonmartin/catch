import Foundation

/// Data-access layer for user-hidden encounters stored in Supabase.
@MainActor
public protocol HiddenEncounterRepository: Sendable {
    func hideEncounter(userID: String, encounterID: String) async throws
    func unhideEncounter(userID: String, encounterID: String) async throws
    func fetchHiddenEncounterIDs(userID: String) async throws -> Set<String>
}
