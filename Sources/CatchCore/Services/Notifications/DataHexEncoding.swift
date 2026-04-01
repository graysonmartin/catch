import Foundation

/// Converts raw `Data` to a lowercase hexadecimal string.
///
/// Extracted as a standalone function so the conversion logic
/// is testable without UIKit dependencies.
public func hexEncodedString(from data: Data) -> String {
    data.map { String(format: "%02x", $0) }.joined()
}
