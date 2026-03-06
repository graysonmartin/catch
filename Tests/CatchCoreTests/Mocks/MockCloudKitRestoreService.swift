import Foundation
import Observation
@testable import CatchCore

@Observable
@MainActor
final class MockCloudKitRestoreService: CloudKitRestoreService {
    private(set) var isRestoring = false
    private(set) var restoreIfNeededCalls: [String] = []

    var restoreResult: CloudKitRestoreResult = CloudKitRestoreResult(catsRestored: 0, encountersRestored: 0)
    var restoreError: (any Error)?

    func restoreIfNeeded(ownerID: String) async throws -> CloudKitRestoreResult {
        restoreIfNeededCalls.append(ownerID)
        if let error = restoreError { throw error }
        return restoreResult
    }

    func reset() {
        restoreIfNeededCalls = []
        restoreResult = CloudKitRestoreResult(catsRestored: 0, encountersRestored: 0)
        restoreError = nil
    }
}
