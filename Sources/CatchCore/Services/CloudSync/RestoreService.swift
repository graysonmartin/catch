import Foundation

/// Describes the result of a data restore operation.
public struct RestoreResult: Sendable, Equatable {
    public let catsRestored: Int
    public let encountersRestored: Int

    public var isEmpty: Bool {
        catsRestored == 0 && encountersRestored == 0
    }

    public init(catsRestored: Int, encountersRestored: Int) {
        self.catsRestored = catsRestored
        self.encountersRestored = encountersRestored
    }
}

/// Orchestrates restoring the user's own cats and encounters
/// back into the local store after a reinstall or new login.
@MainActor
public protocol RestoreService: Observable, Sendable {
    var isRestoring: Bool { get }

    /// Restore the user's data if the local store is empty.
    /// Returns the count of restored items.
    func restoreIfNeeded(ownerID: String) async throws -> RestoreResult
}
