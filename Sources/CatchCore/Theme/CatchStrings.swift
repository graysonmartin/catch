import Foundation

public enum CatchStrings {

    // MARK: - Common

    public enum Common {
        public static let cancel = String(localized: "Cancel")
        public static let save = String(localized: "Save")
        public static let delete = String(localized: "Delete")
        public static let done = String(localized: "Done")
        public static let close = String(localized: "Close")
        public static let edit = String(localized: "Edit")
        public static let date = String(localized: "Date")
        public static let breed = String(localized: "Breed")
        public static let age = String(localized: "Age")
        public static let location = String(localized: "Location")
        public static let notes = String(localized: "Notes")
        public static let photos = String(localized: "Photos")
        public static let name = String(localized: "Name")
        public static let catInfo = String(localized: "Cat Info")
        public static let estimatedAge = String(localized: "Estimated Age")
        public static let iOwnThisCat = String(localized: "I own this cat")
        public static let notesPlaceholder = String(localized: "Notes about this cat...")
        public static let sortBy = String(localized: "sort by")
        public static let unnamedCatFallback = String(localized: "mystery cat")
        public static let unnamedStray = String(localized: "stray / unnamed")

        public static func encounterCount(_ count: Int) -> String {
            String(localized: "\(count) encounter\(count == 1 ? "" : "s")")
        }
    }

    // MARK: - Tabs

    public enum Tabs {
        public static let feed = String(localized: "Feed")
        public static let log = String(localized: "Log")
        public static let map = String(localized: "Map")
        public static let profile = String(localized: "Profile")
    }

    // MARK: - Rate Limiting

    public enum RateLimit {
        public static let likeCooldown = String(localized: "okay we get it, you like cats")
        public static let followCooldown = String(localized: "slow down there, you're following too fast")
        public static let commentCooldown = String(localized: "give it a sec, you're commenting too fast")
        public static let searchCooldown = String(localized: "the search bar needs a breather")
        public static let genericCooldown = String(localized: "chill for a sec, you're going too fast")

        public static func retryIn(_ seconds: Int) -> String {
            String(localized: "try again in \(seconds)s")
        }
    }
}
