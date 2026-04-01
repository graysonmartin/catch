import Foundation

@MainActor
public protocol ReportService: Observable, Sendable {
    var reportedEncounters: Set<String> { get }
    var hiddenEncounterIDs: Set<String> { get }
    func submitReport(encounterRecordName: String, category: ReportCategory, reason: String) async throws
    func hasReported(_ encounterRecordName: String) -> Bool
    func isHidden(_ encounterRecordName: String) -> Bool
    func loadHiddenEncounters() async throws
}
