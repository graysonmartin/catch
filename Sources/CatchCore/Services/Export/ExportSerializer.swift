import Foundation

/// Pure-logic serialization for Catch export files.
/// Encoding and decoding live here so they can be tested without platform dependencies.
public enum ExportSerializer {

    // MARK: - Encode

    /// Encodes an `ExportPayload` to pretty-printed JSON `Data`.
    public static func encode(_ payload: ExportPayload) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(payload)
    }

    // MARK: - Decode

    /// Decodes an `ExportPayload` from JSON `Data`.
    public static func decode(_ data: Data) throws -> ExportPayload {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ExportPayload.self, from: data)
    }

    // MARK: - File Naming

    /// Generates a file name like `catch-backup-2026-03-20.json`.
    public static func backupFileName(date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return "catch-backup-\(formatter.string(from: date)).json"
    }
}
