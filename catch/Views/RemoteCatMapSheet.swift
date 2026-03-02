import Foundation
import CatchCore

struct RemotePinSelection: Identifiable, Hashable {
    let id = UUID()
    let cat: CloudCat?
    let encounters: [CloudEncounter]
    let owner: CloudUserProfile

    static func == (lhs: RemotePinSelection, rhs: RemotePinSelection) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
