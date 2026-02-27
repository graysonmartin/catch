import Foundation
import CatchCore

enum CollectionFilter: String, CaseIterable, Identifiable {
    case ownedOnly = "owned"
    case repeats = "repeats"
    case seenLast7Days = "last 7 days"
    case seenLast30Days = "last 30 days"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ownedOnly: CatchStrings.Collection.filterOwned
        case .repeats: CatchStrings.Collection.filterRepeats
        case .seenLast7Days: CatchStrings.Collection.filterLast7Days
        case .seenLast30Days: CatchStrings.Collection.filterLast30Days
        }
    }

    var icon: String {
        switch self {
        case .ownedOnly: "heart.fill"
        case .repeats: "arrow.2.squarepath"
        case .seenLast7Days: "clock"
        case .seenLast30Days: "calendar"
        }
    }
}
