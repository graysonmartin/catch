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

        // Use CLGeocoder with the full display name — more reliable than
        // MKLocalSearch for disambiguating international locations
        // (e.g. "Geneva, Switzerland" vs "Geneva, IL").
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.geocodeAddressString(result.displayName)
            guard let placemark = placemarks.first,
                  let coordinate = placemark.location?.coordinate else {
                return nil
            }
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
