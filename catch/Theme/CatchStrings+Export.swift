import Foundation
import CatchCore

extension CatchStrings {

    enum Export {
        // Section header
        static let sectionTitle = String(localized: "data")

        // Export
        static let exportButton = String(localized: "export my data")
        static let exportDescription = String(localized: "download all your cats and encounters as a JSON file. your data, your rules.")
        static let exporting = String(localized: "packing your cats...")
        static let exportSuccess = String(localized: "export ready")
        static let exportFailed = String(localized: "export failed. try again?")

        // Import
        static let importButton = String(localized: "import backup")
        static let importDescription = String(localized: "restore from a previous export file.")
        static let importing = String(localized: "unpacking cats...")
        static let importSuccess = String(localized: "data restored successfully")
        static let importFailed = String(localized: "import failed")
        static let importConfirmTitle = String(localized: "import this backup?")
        static let importConfirmAction = String(localized: "import")

        static func importPreview(cats: Int, encounters: Int) -> String {
            String(localized: "this backup has \(cats) cat\(cats == 1 ? "" : "s") and \(encounters) encounter\(encounters == 1 ? "" : "s").")
        }
    }
}
