import Foundation

/// A single autocomplete suggestion from a location search.
public struct LocationSearchResult: Hashable, Sendable {
    public let title: String
    public let subtitle: String

    /// Combined display name (e.g. "Geneva, Switzerland").
    public var displayName: String {
        subtitle.isEmpty ? title : "\(title), \(subtitle)"
    }

    public init(title: String, subtitle: String) {
        self.title = title
        self.subtitle = subtitle
    }
}
