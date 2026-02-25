import Foundation

struct VisibilitySettings: Codable, Equatable, Sendable {
    var showCats: Bool
    var showEncounters: Bool
    var showCareEntries: Bool

    static let `default` = VisibilitySettings(
        showCats: true,
        showEncounters: true,
        showCareEntries: true
    )
}
