import Foundation
@testable import CatchCore

final class MockKeychainService: KeychainService, @unchecked Sendable {
    private var storage: [String: Data] = [:]
    private(set) var saveCallCount = 0
    private(set) var loadCallCount = 0
    private(set) var deleteCallCount = 0

    var shouldThrowOnSave: KeychainError?
    var shouldThrowOnLoad: KeychainError?
    var shouldThrowOnDelete: KeychainError?

    func save(_ data: Data, forKey key: String) throws {
        saveCallCount += 1
        if let error = shouldThrowOnSave {
            throw error
        }
        storage[key] = data
    }

    func load(forKey key: String) throws -> Data? {
        loadCallCount += 1
        if let error = shouldThrowOnLoad {
            throw error
        }
        return storage[key]
    }

    func delete(forKey key: String) throws {
        deleteCallCount += 1
        if let error = shouldThrowOnDelete {
            throw error
        }
        storage.removeValue(forKey: key)
    }

    // MARK: - Test Helpers

    /// Returns current stored data for a key without incrementing counters.
    func peek(forKey key: String) -> Data? {
        storage[key]
    }

    /// Returns whether the storage is empty without incrementing counters.
    var isEmpty: Bool {
        storage.isEmpty
    }
}
