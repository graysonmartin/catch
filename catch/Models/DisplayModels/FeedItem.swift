import Foundation

enum FeedItem: Identifiable {
    case local(Encounter)
    case remote(CloudEncounter, cat: CloudCat?, owner: CloudUserProfile)

    var id: String {
        switch self {
        case .local(let encounter):
            return "local-\(encounter.id)"
        case .remote(let encounter, _, _):
            return "remote-\(encounter.recordName)"
        }
    }

    var date: Date {
        switch self {
        case .local(let encounter):
            return encounter.date
        case .remote(let encounter, _, _):
            return encounter.date
        }
    }

    var isLocal: Bool {
        if case .local = self { return true }
        return false
    }

    var encounterRecordName: String? {
        switch self {
        case .local(let encounter):
            return encounter.cloudKitRecordName
        case .remote(let encounter, _, _):
            return encounter.recordName
        }
    }
}
