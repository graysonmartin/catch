import XCTest
@testable import CatchCore

final class NonceGeneratorTests: XCTestCase {

    func test_randomNonce_defaultLength() {
        let nonce = NonceGenerator.randomNonce()
        XCTAssertEqual(nonce.count, 32)
    }

    func test_randomNonce_customLength() {
        let nonce = NonceGenerator.randomNonce(length: 64)
        XCTAssertEqual(nonce.count, 64)
    }

    func test_randomNonce_uniquePerCall() {
        let a = NonceGenerator.randomNonce()
        let b = NonceGenerator.randomNonce()
        XCTAssertNotEqual(a, b)
    }

    func test_randomNonce_containsOnlyValidCharacters() {
        let charset = Set("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = NonceGenerator.randomNonce(length: 100)
        for char in nonce {
            XCTAssertTrue(charset.contains(char), "Invalid character: \(char)")
        }
    }

    func test_sha256_producesConsistentHash() {
        let hash1 = NonceGenerator.sha256("hello")
        let hash2 = NonceGenerator.sha256("hello")
        XCTAssertEqual(hash1, hash2)
    }

    func test_sha256_producesCorrectLength() {
        // SHA256 hex = 64 characters
        let hash = NonceGenerator.sha256("test")
        XCTAssertEqual(hash.count, 64)
    }

    func test_sha256_differentInputsDifferentHashes() {
        let a = NonceGenerator.sha256("cat")
        let b = NonceGenerator.sha256("dog")
        XCTAssertNotEqual(a, b)
    }

    func test_sha256_knownVector() {
        // SHA256("abc") = ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad
        let hash = NonceGenerator.sha256("abc")
        XCTAssertEqual(hash, "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }
}
