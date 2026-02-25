import Foundation

enum CloudSyncError: LocalizedError, Equatable {
    case notSignedIn
    case recordNotFound
    case uploadFailed
    case fetchFailed

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            "sign in to sync your cats"
        case .recordNotFound:
            "couldn't find that record in the cloud"
        case .uploadFailed:
            "failed to upload, try again later"
        case .fetchFailed:
            "couldn't fetch data from the cloud"
        }
    }
}
