import Foundation
import Observation

@Observable
@MainActor
public final class SupabaseReportService: ReportService {
    public private(set) var reportedEncounters: Set<String> = []

    private let repository: any SupabaseReportRepository
    private let getCurrentUserID: () -> String?
    private let rateLimiter: any RateLimiting

    public init(
        repository: any SupabaseReportRepository,
        getCurrentUserID: @escaping @Sendable () -> String?,
        rateLimiter: any RateLimiting = RateLimiter()
    ) {
        self.repository = repository
        self.getCurrentUserID = getCurrentUserID
        self.rateLimiter = rateLimiter
    }

    public func submitReport(
        encounterRecordName: String,
        category: ReportCategory,
        reason: String
    ) async throws {
        guard let userID = getCurrentUserID() else {
            throw ReportError.notSignedIn
        }

        try rateLimiter.checkAllowed(.report)

        let encounterID = encounterRecordName.lowercased()

        let existing = try await repository.fetchUserReport(
            encounterID: encounterID,
            reporterID: userID
        )
        if existing != nil {
            throw ReportError.alreadyReported
        }

        let payload = SupabaseReportInsertPayload(
            encounterID: encounterID,
            reporterID: userID,
            category: category.rawValue,
            reason: reason.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        do {
            _ = try await repository.insertReport(payload: payload)
            rateLimiter.recordAction(.report)
            reportedEncounters.insert(encounterID)
        } catch {
            throw ReportError.networkError(error.localizedDescription)
        }
    }

    public func hasReported(_ encounterRecordName: String) -> Bool {
        reportedEncounters.contains(encounterRecordName.lowercased())
    }
}
