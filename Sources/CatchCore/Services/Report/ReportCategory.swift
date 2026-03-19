import Foundation

/// Categories for reporting encounter content.
public enum ReportCategory: String, CaseIterable, Sendable {
    case spam
    case inappropriate
    case harassment
    case other
}
