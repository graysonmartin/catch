import Foundation
import CatchCore

extension CatchStrings {

    enum DataExport {
        static let exportButton = String(localized: "export data")
        static let exportTitle = String(localized: "export your cats")
        static let exportSubtitle = String(localized: "saves all your cats and encounters as a JSON file. photos not included — they're too thicc for a text file.")
        static let exporting = String(localized: "packing up your cats...")
        static let exportFailed = String(localized: "export failed")
        static let exportFailedMessage = String(localized: "something went sideways. try again maybe?")
        static let nothingToExport = String(localized: "you have zero cats. go outside.")

        static func exportFileName(_ date: Date) -> String {
            let formatted = date.formatted(.dateTime.year().month().day())
            return "catch-export-\(formatted).json"
        }
    }
}
