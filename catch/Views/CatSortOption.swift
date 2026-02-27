import Foundation
import CatchCore

enum CatSortOption: String, CaseIterable, Identifiable {
    case name = "name"
    case encounters = "most seen"
    case recent = "recently seen"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .name: CatchStrings.Collection.sortName
        case .encounters: CatchStrings.Collection.sortMostSeen
        case .recent: CatchStrings.Collection.sortRecentlySeen
        }
    }
}
