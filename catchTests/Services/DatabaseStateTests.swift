import XCTest
import SwiftData

@MainActor
final class DatabaseStateTests: XCTestCase {

    func testInitProducesReadyStatus() {
        let state = DatabaseState()

        switch state.status {
        case .ready:
            break // expected
        case .failed(let message):
            XCTFail("Expected .ready but got .failed(\(message))")
        }
    }

    func testRetryProducesReadyStatus() {
        let state = DatabaseState()
        state.retry()

        switch state.status {
        case .ready:
            break // expected
        case .failed(let message):
            XCTFail("Expected .ready after retry but got .failed(\(message))")
        }
    }

    func testResetAndRetryProducesReadyStatus() {
        let state = DatabaseState()
        state.resetAndRetry()

        switch state.status {
        case .ready:
            break // expected
        case .failed(let message):
            XCTFail("Expected .ready after resetAndRetry but got .failed(\(message))")
        }
    }
}
