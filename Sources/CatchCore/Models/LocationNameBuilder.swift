import Foundation

/// Builds a display name from location components (e.g. from reverse geocoding).
public enum LocationNameBuilder {

    /// Builds a comma-separated display name from optional address components.
    /// Nil and empty components are filtered out.
    public static func buildName(
        name: String?,
        locality: String?,
        administrativeArea: String?
    ) -> String {
        let parts = [name, locality, administrativeArea]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        return parts.joined(separator: ", ")
    }
}
