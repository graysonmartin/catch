import Foundation
import CatchCore

extension CatchStrings {

    enum Map {
        static let emptyTitle = String(localized: "no locations yet")
        static let emptySubtitle = String(localized: "cats with GPS coordinates will appear here. use the location button when logging encounters.")
        static let emptyAction = String(localized: "log a cat")

        static func catsHere(_ count: Int) -> String {
            String(localized: "\(count) Cats Here")
        }

        // Missing location
        static let missingLocationsTitle = String(localized: "missing locations")
        static let noLocationSet = String(localized: "no location set")

        static func catsNotShown(_ count: Int) -> String {
            String(localized: "\(count) cat\(count == 1 ? "" : "s") not shown")
        }

        // Remote cat detail
        static let lastSeen = String(localized: "last seen")
        static func spottedBy(_ name: String) -> String {
            String(localized: "spotted by \(name)")
        }

        // Filters
        static let myCats = String(localized: "my cats")
        static let friendsCats = String(localized: "friends' cats")
        static let last7Days = String(localized: "last 7 days")
        static let last30Days = String(localized: "last 30 days")
        static let allTime = String(localized: "all time")
        static let resetFilters = String(localized: "reset")
    }
}
