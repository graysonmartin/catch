import Foundation

/// Pure-logic serialization for Catch export files.
/// Encoding and decoding live here so they can be tested without platform dependencies.
public enum ExportSerializer {

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    // MARK: - Encode

    public static func encode(_ payload: ExportPayload) throws -> Data {
        try encoder.encode(payload)
    }

    // MARK: - Decode

    public static func decode(_ data: Data) throws -> ExportPayload {
        try decoder.decode(ExportPayload.self, from: data)
    }

    // MARK: - File Naming

    public static func backupFileName(date: Date = Date()) -> String {
        "catch-backup-\(dateFormatter.string(from: date)).json"
    }
}
