import Foundation

struct Friendship: Sendable, Equatable, Identifiable {
    let id: String
    let userA: String
    let userB: String
    let createdAt: Date

    func friendID(for currentUserID: String) -> String {
        currentUserID == userA ? userB : userA
    }

    static func recordName(userID1: String, userID2: String) -> String {
        let sorted = [userID1, userID2].sorted()
        return "\(sorted[0])_\(sorted[1])"
    }
}
