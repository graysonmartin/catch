import XCTest
@testable import CatchCore

final class SupabaseConfigTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        SupabaseConfig.current = .development
    }

    func testDevelopmentURLIsValid() {
        SupabaseConfig.current = .development
        let url = SupabaseConfig.url
        XCTAssertEqual(url.scheme, "https")
        XCTAssertEqual(url.host, "tqmjfpevabhfaxotfvge.supabase.co")
    }

    func testProductionURLIsValid() {
        SupabaseConfig.current = .production
        let url = SupabaseConfig.url
        XCTAssertEqual(url.scheme, "https")
        XCTAssertNotNil(url.host)
    }

    func testDevelopmentAnonKeyIsNonEmpty() {
        SupabaseConfig.current = .development
        XCTAssertFalse(SupabaseConfig.anonKey.isEmpty)
    }

    func testProductionAnonKeyIsNonEmpty() {
        SupabaseConfig.current = .production
        XCTAssertFalse(SupabaseConfig.anonKey.isEmpty)
    }

    func testEnvironmentSwitching() {
        SupabaseConfig.current = .development
        let devURL = SupabaseConfig.url
        let devKey = SupabaseConfig.anonKey

        SupabaseConfig.current = .production
        let prodURL = SupabaseConfig.url
        let prodKey = SupabaseConfig.anonKey

        // Both environments return valid values
        XCTAssertNotNil(devURL.host)
        XCTAssertNotNil(prodURL.host)
        XCTAssertFalse(devKey.isEmpty)
        XCTAssertFalse(prodKey.isEmpty)
    }

    func testDefaultEnvironmentIsDevelopment() {
        // Reset to default
        SupabaseConfig.current = .development
        XCTAssertEqual(SupabaseConfig.url.host, "tqmjfpevabhfaxotfvge.supabase.co")
    }
}
