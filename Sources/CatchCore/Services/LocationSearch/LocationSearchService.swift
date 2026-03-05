import Foundation

/// Provides location autocomplete search and coordinate resolution.
@MainActor
public protocol LocationSearchService: Observable, AnyObject {
    /// Current autocomplete suggestions based on the query fragment.
    var suggestions: [LocationSearchResult] { get }

    /// Whether the service is currently resolving coordinates for a selection.
    var isResolving: Bool { get }

    /// Updates the query fragment and triggers autocomplete.
    func updateQuery(_ fragment: String)

    /// Resolves a selected suggestion to a `Location` with coordinates.
    func resolve(_ result: LocationSearchResult) async -> Location?

    /// Clears current suggestions and resets state.
    func clear()
}
