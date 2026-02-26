import Foundation

enum ProfileMode {
    case own
    case remote(userID: String, initialDisplayName: String?)
}
