import Foundation

/// Errors that can occur during Keychain operations.
public enum KeychainError: Error, Equatable, Sendable {
    case encodingFailed
    case decodingFailed
    case unexpectedStatus(Int32)
}

/// Protocol for secure credential storage using the system Keychain.
public protocol KeychainService: Sendable {
    /// Saves data for the given key, overwriting any existing value.
    func save(_ data: Data, forKey key: String) throws

    /// Loads data for the given key. Returns `nil` if no entry exists.
    func load(forKey key: String) throws -> Data?

    /// Deletes the entry for the given key. No-op if the key doesn't exist.
    func delete(forKey key: String) throws
}
