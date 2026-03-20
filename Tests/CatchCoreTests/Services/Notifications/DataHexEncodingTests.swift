import XCTest
@testable import CatchCore

final class DataHexEncodingTests: XCTestCase {

    func test_emptyData_returnsEmptyString() {
        let result = hexEncodedString(from: Data())
        XCTAssertEqual(result, "")
    }

    func test_singleByte_returnsHexPair() {
        let data = Data([0xFF])
        XCTAssertEqual(hexEncodedString(from: data), "ff")
    }

    func test_singleByte_zeroPadded() {
        let data = Data([0x0A])
        XCTAssertEqual(hexEncodedString(from: data), "0a")
    }

    func test_zeroByte_returnsTwoZeros() {
        let data = Data([0x00])
        XCTAssertEqual(hexEncodedString(from: data), "00")
    }

    func test_multipleBytes_concatenated() {
        let data = Data([0xDE, 0xAD, 0xBE, 0xEF])
        XCTAssertEqual(hexEncodedString(from: data), "deadbeef")
    }

    func test_realisticAPNsToken_correctLength() {
        // APNs tokens are 32 bytes (64 hex chars)
        let tokenBytes: [UInt8] = (0..<32).map { UInt8($0) }
        let data = Data(tokenBytes)
        let hex = hexEncodedString(from: data)
        XCTAssertEqual(hex.count, 64)
        XCTAssertTrue(hex.hasPrefix("000102030405"))
    }

    func test_alwaysLowercase() {
        let data = Data([0xAB, 0xCD, 0xEF])
        let hex = hexEncodedString(from: data)
        XCTAssertEqual(hex, hex.lowercased())
    }
}
