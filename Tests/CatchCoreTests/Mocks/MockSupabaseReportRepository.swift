import Foundation
@testable import CatchCore

@MainActor
final class MockSupabaseReportRepository: SupabaseReportRepository {

    // MARK: - Call Tracking

    var insertReportCalls: [SupabaseReportInsertPayload] = []
    var fetchUserReportCalls: [(encounterID: String, reporterID: String)] = []

    // MARK: - Stubbed Results

    var insertReportResult: SupabaseReport?
    var insertReportError: (any Error)?
    var fetchUserReportResult: SupabaseReport?
    var fetchUserReportError: (any Error)?

    // MARK: - Protocol

    func insertReport(payload: SupabaseReportInsertPayload) async throws -> SupabaseReport {
        insertReportCalls.append(payload)
        if let insertReportError { throw insertReportError }
        guard let result = insertReportResult else {
            throw NSError(domain: "MockSupabaseReportRepository", code: 0)
        }
        return result
    }

    func fetchUserReport(encounterID: String, reporterID: String) async throws -> SupabaseReport? {
        fetchUserReportCalls.append((encounterID, reporterID))
        if let fetchUserReportError { throw fetchUserReportError }
        return fetchUserReportResult
    }
}

// MARK: - Test Fixtures

extension SupabaseReport {
    static func fixture(
        id: UUID = UUID(),
        encounterID: UUID = UUID(),
        reporterID: UUID = UUID(),
        category: String = "spam",
        reason: String = "",
        status: String = "pending",
        createdAt: Date = Date()
    ) -> SupabaseReport {
        SupabaseReport(
            id: id,
            encounterID: encounterID,
            reporterID: reporterID,
            category: category,
            reason: reason,
            status: status,
            createdAt: createdAt
        )
    }
}
