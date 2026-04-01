import Foundation

enum AppRoute: Equatable, Hashable {
    case encounter(id: String)
    case profile(id: String)
}

/// Identifiable wrapper for a routed profile ID, enabling `.sheet(item:)` presentation.
struct RoutedProfileId: Identifiable, Equatable {
    let id: String
}
