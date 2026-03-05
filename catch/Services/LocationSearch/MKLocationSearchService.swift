import MapKit
import Observation
import CatchCore

/// MapKit-backed location autocomplete service using `MKLocalSearchCompleter`.
@MainActor
@Observable
final class MKLocationSearchService: NSObject, LocationSearchService {
    private(set) var suggestions: [LocationSearchResult] = []
    private(set) var isResolving = false

    private let completer = MKLocalSearchCompleter()
    private var completerDelegate: CompleterDelegate?

    /// Maps each suggestion back to its original `MKLocalSearchCompletion`
    /// so `resolve()` can use `MKLocalSearch.Request(completion:)`.
    private var completionLookup: [LocationSearchResult: MKLocalSearchCompletion] = [:]

    override init() {
        super.init()
        let delegate = CompleterDelegate { [weak self] results, completions in
            self?.completionLookup = completions
            self?.suggestions = results
        }
        completerDelegate = delegate
        completer.delegate = delegate
        completer.resultTypes = .address
    }

    func updateQuery(_ fragment: String) {
        let trimmed = fragment.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            clear()
            return
        }
        completer.queryFragment = trimmed
    }

    func resolve(_ result: LocationSearchResult) async -> Location? {
        isResolving = true
        defer { isResolving = false }

        let request: MKLocalSearch.Request
        if let completion = completionLookup[result] {
            // Use the exact completion the user tapped — avoids ambiguous re-search
            request = MKLocalSearch.Request(completion: completion)
        } else {
            // Defensive fallback: natural language query
            request = MKLocalSearch.Request()
            request.naturalLanguageQuery = result.displayName
        }

        do {
            let response = try await MKLocalSearch(request: request).start()
            guard let item = response.mapItems.first else { return nil }
            let coordinate = item.placemark.coordinate
            return Location(
                name: result.displayName,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
        } catch {
            return nil
        }
    }

    func clear() {
        completer.cancel()
        suggestions = []
        completionLookup = [:]
    }
}

// MARK: - MKLocalSearchCompleterDelegate

private final class CompleterDelegate: NSObject, MKLocalSearchCompleterDelegate {
    private let onUpdate: @MainActor (
        [LocationSearchResult],
        [LocationSearchResult: MKLocalSearchCompletion]
    ) -> Void

    init(onUpdate: @escaping @MainActor (
        [LocationSearchResult],
        [LocationSearchResult: MKLocalSearchCompletion]
    ) -> Void) {
        self.onUpdate = onUpdate
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let completions = Array(completer.results.prefix(5))
        var lookup: [LocationSearchResult: MKLocalSearchCompletion] = [:]
        let results = completions.map { completion in
            let result = LocationSearchResult(
                title: completion.title,
                subtitle: completion.subtitle
            )
            lookup[result] = completion
            return result
        }
        Task { @MainActor in
            self.onUpdate(results, lookup)
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // Autocomplete errors are transient — clear suggestions silently
        Task { @MainActor in
            self.onUpdate([], [:])
        }
    }
}
