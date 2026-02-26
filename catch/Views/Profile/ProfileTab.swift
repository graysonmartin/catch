import Foundation

enum ProfileTab: String, CaseIterable, Identifiable {
    case collection
    case diary

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .collection: CatchStrings.Profile.collectionTab
        case .diary: CatchStrings.Profile.diaryTab
        }
    }
}
