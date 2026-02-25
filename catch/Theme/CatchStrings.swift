import Foundation

enum CatchStrings {

    // MARK: - Common

    enum Common {
        static let cancel = String(localized: "Cancel")
        static let save = String(localized: "Save")
        static let delete = String(localized: "Delete")
        static let done = String(localized: "Done")
        static let close = String(localized: "Close")
        static let edit = String(localized: "Edit")
        static let date = String(localized: "Date")
        static let breed = String(localized: "Breed")
        static let age = String(localized: "Age")
        static let location = String(localized: "Location")
        static let notes = String(localized: "Notes")
        static let photos = String(localized: "Photos")
        static let name = String(localized: "Name")
        static let catInfo = String(localized: "Cat Info")
        static let estimatedAge = String(localized: "Estimated Age")
        static let iOwnThisCat = String(localized: "I own this cat")
        static let notesPlaceholder = String(localized: "Notes about this cat...")
        static let sortBy = String(localized: "sort by")

        static func encounterCount(_ count: Int) -> String {
            String(localized: "\(count) encounter\(count == 1 ? "" : "s")")
        }
    }

    // MARK: - Tabs

    enum Tabs {
        static let feed = String(localized: "Feed")
        static let log = String(localized: "Log")
        static let map = String(localized: "Map")
        static let collection = String(localized: "Collection")
        static let profile = String(localized: "Profile")
    }
}
