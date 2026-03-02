import Foundation

public protocol DataExportService: Sendable {
    func exportData() async throws -> ExportData
    func encodeToJSON(_ data: ExportData) throws -> Data
}

public enum DataExportError: Error, Equatable {
    case encodingFailed
    case noDataToExport
}
