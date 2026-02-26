import Foundation

extension CatchStrings {

    enum Diary {
        static let emptyTitle = String(localized: "no entries yet")
        static let emptySubtitle = String(localized: "your diary is a blank page. go find some cats.")
        static let searchPrompt = String(localized: "search diary")
        static let noDiaryTitle = String(localized: "no diary entries")
        static let noDiarySubtitle = String(localized: "they haven't written anything down yet")

        static func searchEmptySubtitle(_ query: String) -> String {
            String(localized: "nothing matching \"\(query)\" in the diary")
        }
    }
}
