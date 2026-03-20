import XCTest

@MainActor
final class UserDefaultsSettingsServiceTests: XCTestCase {

    // MARK: - Version Info

    func test_appVersion_returnsNonEmptyString() {
        let service = UserDefaultsSettingsService()
        let version = service.appVersion()
        // In test target, Bundle.main may not have version info
        // Just verify it returns something (either the version or the fallback)
        XCTAssertFalse(version.isEmpty)
    }

    func test_buildNumber_returnsNonEmptyString() {
        let service = UserDefaultsSettingsService()
        let build = service.buildNumber()
        XCTAssertFalse(build.isEmpty)
    }

    // MARK: - Mock Service

    func test_mockService_returnsConfiguredValues() {
        let mock = MockSettingsService()
        mock.stubbedAppVersion = "2.5.0"
        mock.stubbedBuildNumber = "99"

        XCTAssertEqual(mock.appVersion(), "2.5.0")
        XCTAssertEqual(mock.buildNumber(), "99")
    }

}
