import Foundation

struct Location: Codable, Hashable {
    var name: String
    var latitude: Double?
    var longitude: Double?

    var hasCoordinates: Bool {
        latitude != nil && longitude != nil
    }

    static let empty = Location(name: "")
}
