import XCTest
@testable import CatchCore

final class MockKeychainServiceTests: XCTestCase {

    private var sut: MockKeychainService!

    override func setUp() {
        super.setUp()
        sut = MockKeychainService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Save & Load

    func test_save_thenLoad_returnsData() throws {
        let data = Data("hello".utf8)
        try sut.save(data, forKey: "key1")
        let loaded = try sut.load(forKey: "key1")
        XCTAssertEqual(loaded, data)
    }

    func test_save_overwritesExistingValue() throws {
        let original = Data("original".utf8)
        let updated = Data("updated".utf8)

        try sut.save(original, forKey: "key1")
        try sut.save(updated, forKey: "key1")

        let loaded = try sut.load(forKey: "key1")
        XCTAssertEqual(loaded, updated)
    }

    func test_load_nonexistentKey_returnsNil() throws {
        let loaded = try sut.load(forKey: "nonexistent")
        XCTAssertNil(loaded)
    }

    // MARK: - Delete

    func test_delete_removesValue() throws {
        let data = Data("toDelete".utf8)
        try sut.save(data, forKey: "key1")
        try sut.delete(forKey: "key1")

        let loaded = try sut.load(forKey: "key1")
        XCTAssertNil(loaded)
    }

    func test_delete_nonexistentKey_doesNotThrow() throws {
        XCTAssertNoThrow(try sut.delete(forKey: "nonexistent"))
    }

    // MARK: - Multiple Keys

    func test_multipleKeys_areIndependent() throws {
        let data1 = Data("value1".utf8)
        let data2 = Data("value2".utf8)

        try sut.save(data1, forKey: "key1")
        try sut.save(data2, forKey: "key2")

        XCTAssertEqual(try sut.load(forKey: "key1"), data1)
        XCTAssertEqual(try sut.load(forKey: "key2"), data2)

        try sut.delete(forKey: "key1")
        XCTAssertNil(try sut.load(forKey: "key1"))
        XCTAssertEqual(try sut.load(forKey: "key2"), data2)
    }

    // MARK: - Error Handling

    func test_save_throwsWhenConfigured() {
        sut.shouldThrowOnSave = .unexpectedStatus(-1)
        XCTAssertThrowsError(try sut.save(Data(), forKey: "key")) { error in
            XCTAssertEqual(error as? KeychainError, .unexpectedStatus(-1))
        }
    }

    func test_load_throwsWhenConfigured() {
        sut.shouldThrowOnLoad = .unexpectedStatus(-2)
        XCTAssertThrowsError(try sut.load(forKey: "key")) { error in
            XCTAssertEqual(error as? KeychainError, .unexpectedStatus(-2))
        }
    }

    func test_delete_throwsWhenConfigured() {
        sut.shouldThrowOnDelete = .unexpectedStatus(-3)
        XCTAssertThrowsError(try sut.delete(forKey: "key")) { error in
            XCTAssertEqual(error as? KeychainError, .unexpectedStatus(-3))
        }
    }

    // MARK: - Call Tracking

    func test_callCounts_areTracked() throws {
        XCTAssertEqual(sut.saveCallCount, 0)
        XCTAssertEqual(sut.loadCallCount, 0)
        XCTAssertEqual(sut.deleteCallCount, 0)

        try sut.save(Data(), forKey: "k")
        XCTAssertEqual(sut.saveCallCount, 1)

        _ = try sut.load(forKey: "k")
        XCTAssertEqual(sut.loadCallCount, 1)

        try sut.delete(forKey: "k")
        XCTAssertEqual(sut.deleteCallCount, 1)
    }

    // MARK: - Codable Round-Trip (AppleUser via Keychain)

    func test_appleUser_roundTrip_viaKeychain() throws {
        let user = AuthUser(id: "user-123", email: "cat@catch.app", fullName: "Cat Fan", provider: .apple)
        let data = try JSONEncoder().encode(user)
        try sut.save(data, forKey: "catch.appleUser")

        let loadedData = try XCTUnwrap(sut.load(forKey: "catch.appleUser"))
        let decoded = try JSONDecoder().decode(AppleUser.self, from: loadedData)
        XCTAssertEqual(decoded, user)
    }

    func test_appleUser_roundTrip_nilOptionals() throws {
        let user = AuthUser(id: "user-456", email: nil, fullName: nil, provider: .apple)
        let data = try JSONEncoder().encode(user)
        try sut.save(data, forKey: "catch.appleUser")

        let loadedData = try XCTUnwrap(sut.load(forKey: "catch.appleUser"))
        let decoded = try JSONDecoder().decode(AppleUser.self, from: loadedData)
        XCTAssertEqual(decoded, user)
        XCTAssertNil(decoded.fullName)
        XCTAssertNil(decoded.email)
    }

    // MARK: - KeychainError Equatable

    func test_keychainError_equatable() {
        XCTAssertEqual(KeychainError.unexpectedStatus(42), KeychainError.unexpectedStatus(42))
        XCTAssertNotEqual(KeychainError.unexpectedStatus(1), KeychainError.unexpectedStatus(2))
    }

    // MARK: - Test Helpers

    func test_peek_doesNotIncrementLoadCount() throws {
        try sut.save(Data("peeked".utf8), forKey: "peekKey")
        let peeked = sut.peek(forKey: "peekKey")
        XCTAssertNotNil(peeked)
        XCTAssertEqual(sut.loadCallCount, 0)
    }

    func test_isEmpty_reflectsStorageState() throws {
        XCTAssertTrue(sut.isEmpty)
        try sut.save(Data("x".utf8), forKey: "k")
        XCTAssertFalse(sut.isEmpty)
        try sut.delete(forKey: "k")
        XCTAssertTrue(sut.isEmpty)
    }
}
