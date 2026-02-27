import Foundation

public struct VisibilitySettings: Codable, Equatable, Sendable {
    public var showCats: Bool
    public var showEncounters: Bool

    public static let `default` = VisibilitySettings(
        showCats: true,
        showEncounters: true
    )

    public init(showCats: Bool, showEncounters: Bool) {
        self.showCats = showCats
        self.showEncounters = showEncounters
    }
}
