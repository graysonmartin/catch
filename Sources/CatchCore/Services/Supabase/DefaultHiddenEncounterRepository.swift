import Foundation
import Supabase

@MainActor
public final class DefaultHiddenEncounterRepository: HiddenEncounterRepository, @unchecked Sendable {
    private let clientProvider: any SupabaseClientProviding
    private static let table = "hidden_encounters"

    public init(clientProvider: any SupabaseClientProviding) {
        self.clientProvider = clientProvider
    }

    public func hideEncounter(userID: String, encounterID: String) async throws {
        let payload = HiddenEncounterPayload(userID: userID, encounterID: encounterID)
        try await clientProvider.client
            .from(Self.table)
            .upsert(payload)
            .execute()
    }

    public func unhideEncounter(userID: String, encounterID: String) async throws {
        try await clientProvider.client
            .from(Self.table)
            .delete()
            .eq("user_id", value: userID)
            .eq("encounter_id", value: encounterID)
            .execute()
    }

    public func fetchHiddenEncounterIDs(userID: String) async throws -> Set<String> {
        let rows: [HiddenEncounterRow] = try await clientProvider.client
            .from(Self.table)
            .select("encounter_id")
            .eq("user_id", value: userID)
            .execute()
            .value
        return Set(rows.map(\.encounterID))
    }
}

private struct HiddenEncounterPayload: Codable, Sendable {
    let userID: String
    let encounterID: String

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case encounterID = "encounter_id"
    }
}

private struct HiddenEncounterRow: Codable, Sendable {
    let encounterID: String

    enum CodingKeys: String, CodingKey {
        case encounterID = "encounter_id"
    }
}
