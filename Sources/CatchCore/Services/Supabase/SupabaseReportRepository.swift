import Foundation

/// Data-access layer for encounter reports stored in Supabase.
@MainActor
public protocol SupabaseReportRepository: Sendable {
    func insertReport(payload: SupabaseReportInsertPayload) async throws -> SupabaseReport
    func fetchUserReport(encounterID: String, reporterID: String) async throws -> SupabaseReport?
}
