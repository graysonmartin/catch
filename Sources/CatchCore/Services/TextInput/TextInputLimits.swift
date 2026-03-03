import Foundation

/// Centralized character limits for all free-text input fields.
public enum TextInputLimits {
    public static let catName = 50
    public static let catNotes = 500
    public static let encounterNotes = 500
    public static let bio = 300
    public static let comment = 500

    /// Percentage threshold at which the character count indicator appears (0.0–1.0).
    public static let warningThreshold: Double = 0.9

    /// Returns the number of characters remaining for the given text and limit.
    public static func remaining(text: String, limit: Int) -> Int {
        max(0, limit - text.count)
    }

    /// Whether the text has reached or exceeded the limit.
    public static func isAtLimit(text: String, limit: Int) -> Bool {
        text.count >= limit
    }

    /// Whether the character count indicator should be visible (past the warning threshold).
    public static func shouldShowCount(text: String, limit: Int) -> Bool {
        guard limit > 0 else { return false }
        let usage = Double(text.count) / Double(limit)
        return usage >= warningThreshold
    }

    /// Truncates the text to fit within the limit, if necessary.
    public static func enforceLimit(text: String, limit: Int) -> String {
        guard text.count > limit else { return text }
        return String(text.prefix(limit))
    }
}
