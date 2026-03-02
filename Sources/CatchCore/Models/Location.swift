import Foundation

public struct Location: Codable, Hashable, Sendable {
    public var name: String
    public var latitude: Double?
    public var longitude: Double?

    public var hasCoordinates: Bool {
        latitude != nil && longitude != nil
    }

    public static let empty = Location(name: "")

    public init(name: String, latitude: Double? = nil, longitude: Double? = nil) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }
}
