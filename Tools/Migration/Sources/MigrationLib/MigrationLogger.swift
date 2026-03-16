import Foundation

/// Simple logger for migration progress and errors.
public enum MigrationLogger {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    public static func info(_ message: String) {
        let timestamp = dateFormatter.string(from: Date())
        print("[\(timestamp)] INFO  \(message)")
    }

    public static func warn(_ message: String) {
        let timestamp = dateFormatter.string(from: Date())
        print("[\(timestamp)] WARN  \(message)")
    }

    public static func error(_ message: String) {
        let timestamp = dateFormatter.string(from: Date())
        print("[\(timestamp)] ERROR \(message)")
    }

    public static func step(_ step: Int, of total: Int, _ message: String) {
        let timestamp = dateFormatter.string(from: Date())
        print("[\(timestamp)] STEP  [\(step)/\(total)] \(message)")
    }

    public static func summary(_ title: String, counts: [(String, Int)]) {
        print("")
        print("=== \(title) ===")
        for (label, count) in counts {
            print("  \(label): \(count)")
        }
        print("")
    }
}
