import Foundation

/// Row returned from the `encounter_reports` table.
public struct SupabaseReport: Codable, Sendable {
    public let id: UUID
    public let encounterID: UUID
    public let reporterID: UUID
    public let category: String
    public let reason: String
    public let status: String
    public let createdAt: Date

    public init(
        id: UUID,
        encounterID: UUID,
        reporterID: UUID,
        category: String,
        reason: String,
        status: String,
        createdAt: Date
    ) {
        self.id = id
        self.encounterID = encounterID
        self.reporterID = reporterID
        self.category = category
        self.reason = reason
        self.status = status
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case encounterID = "encounter_id"
        case reporterID = "reporter_id"
        case category
        case reason
        case status
        case createdAt = "created_at"
    }
}

/// Payload for inserting a report row.
public struct SupabaseReportInsertPayload: Codable, Sendable {
    public let encounterID: String
    public let reporterID: String
    public let category: String
    public let reason: String

    public init(encounterID: String, reporterID: String, category: String, reason: String) {
        self.encounterID = encounterID
        self.reporterID = reporterID
        self.category = category
        self.reason = reason
    }

    enum CodingKeys: String, CodingKey {
        case encounterID = "encounter_id"
        case reporterID = "reporter_id"
        case category
        case reason
    }
}
