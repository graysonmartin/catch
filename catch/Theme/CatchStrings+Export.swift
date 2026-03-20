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
    }
}
