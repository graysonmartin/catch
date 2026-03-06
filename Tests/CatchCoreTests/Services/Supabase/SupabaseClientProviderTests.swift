import XCTest
import Supabase
@testable import CatchCore

@MainActor
final class SupabaseClientProviderTests: XCTestCase {
    func testInitWithDefaults() {
        let provider = SupabaseClientProvider()
        XCTAssertNotNil(provider.client)
    }

    func testInitWithCustomConfig() {
        let customURL = URL(string: "https://custom.supabase.co")!
        let customKey = "custom-anon-key"
        let provider = SupabaseClientProvider(url: customURL, key: customKey)
        XCTAssertNotNil(provider.client)
    }

    func testConformsToProtocol() {
        let provider = SupabaseClientProvider()
        let providing: any SupabaseClientProviding = provider
        XCTAssertNotNil(providing.client)
    }

    func testMockProvider() {
        let mock = MockSupabaseClientProvider()
        let providing: any SupabaseClientProviding = mock
        XCTAssertNotNil(providing.client)
    }
}
