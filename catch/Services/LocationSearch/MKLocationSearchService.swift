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

    override init() {
        super.init()
        let delegate = CompleterDelegate { [weak self] results in
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

        // Search with a global region to prevent local bias —
        // ensures "Geneva, Switzerland" resolves to Switzerland, not a nearby US city.
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = result.displayName
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            span: MKCoordinateSpan(latitudeDelta: 180, longitudeDelta: 360)
        )

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
    }
}

// MARK: - MKLocalSearchCompleterDelegate

private final class CompleterDelegate: NSObject, MKLocalSearchCompleterDelegate {
    private let onUpdate: @MainActor ([LocationSearchResult]) -> Void

    init(onUpdate: @escaping @MainActor ([LocationSearchResult]) -> Void) {
        self.onUpdate = onUpdate
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let results = completer.results.prefix(5).map { completion in
            LocationSearchResult(
                title: completion.title,
                subtitle: completion.subtitle
            )
        }
        Task { @MainActor in
            self.onUpdate(Array(results))
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            self.onUpdate([])
        }
    }
}
