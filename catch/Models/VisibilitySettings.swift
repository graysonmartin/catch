import Foundation

struct VisibilitySettings: Codable, Equatable, Sendable {
    var showCats: Bool
    var showEncounters: Bool

    static let `default` = VisibilitySettings(
        showCats: true,
        showEncounters: true
    )
}
