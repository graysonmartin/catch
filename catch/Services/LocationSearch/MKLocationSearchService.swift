import MapKit
import Observation
import CoreLocation
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
    /// so `resolve()` can use the completion's internal identifier.
    private var completionLookup: [LocationSearchResult: MKLocalSearchCompletion] = [:]

    override init() {
        super.init()
        let delegate = CompleterDelegate { [weak self] results, completions in
            self?.completionLookup.merge(completions) { _, new in new }
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

        // 1) Try completion-based search (uses MapKit's internal place ID)
        if let completion = completionLookup[result] {
            if let location = await search(MKLocalSearch.Request(completion: completion),
                                           displayName: result.displayName) {
                return location
            }
        }

        // 2) Fallback: CLGeocoder with full display name
        if let location = await geocode(result.displayName) {
            return location
        }

        // 3) Last resort: natural language search with global region
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = result.displayName
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            span: MKCoordinateSpan(latitudeDelta: 180, longitudeDelta: 360)
        )
        return await search(request, displayName: result.displayName)
    }

    func clear() {
        completer.cancel()
        suggestions = []
        completionLookup = [:]
    }

    // MARK: - Private

    private func search(_ request: MKLocalSearch.Request, displayName: String) async -> Location? {
        do {
            let response = try await MKLocalSearch(request: request).start()
            guard let item = response.mapItems.first else { return nil }
            let coordinate = item.placemark.coordinate
            return Location(
                name: displayName,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
        } catch {
            return nil
        }
    }

    private func geocode(_ address: String) async -> Location? {
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.geocodeAddressString(address)
            guard let placemark = placemarks.first,
                  let coordinate = placemark.location?.coordinate else { return nil }
            return Location(
                name: address,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
        } catch {
            return nil
        }
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
        Task { @MainActor in
            self.onUpdate([], [:])
        }
    }
}
