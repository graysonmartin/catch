import Foundation
import Supabase

@MainActor
public final class DefaultSupabaseReportRepository: SupabaseReportRepository, @unchecked Sendable {
    private let clientProvider: any SupabaseClientProviding
    private static let table = "encounter_reports"

    public init(clientProvider: any SupabaseClientProviding) {
        self.clientProvider = clientProvider
    }

    public func insertReport(payload: SupabaseReportInsertPayload) async throws -> SupabaseReport {
        try await clientProvider.client
            .from(Self.table)
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
    }

    public func fetchUserReport(encounterID: String, reporterID: String) async throws -> SupabaseReport? {
        let response: [SupabaseReport] = try await clientProvider.client
            .from(Self.table)
            .select()
            .eq("encounter_id", value: encounterID)
            .eq("reporter_id", value: reporterID)
            .limit(1)
            .execute()
            .value
        return response.first
    }
}
