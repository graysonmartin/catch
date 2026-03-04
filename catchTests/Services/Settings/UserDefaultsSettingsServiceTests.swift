import XCTest

@MainActor
final class UserDefaultsSettingsServiceTests: XCTestCase {

    private let testKey = "catch.settings.notificationsEnabled"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: testKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: testKey)
        super.tearDown()
    }

    // MARK: - Notifications Default

    func test_notificationsEnabled_defaultsToTrue() {
        let service = UserDefaultsSettingsService()
        XCTAssertTrue(service.isNotificationsEnabled)
    }

    // MARK: - Notifications Toggle Persists

    func test_settingNotificationsToFalse_persists() {
        let service = UserDefaultsSettingsService()
        service.isNotificationsEnabled = false

        let service2 = UserDefaultsSettingsService()
        XCTAssertFalse(service2.isNotificationsEnabled)
    }

    func test_settingNotificationsToTrue_persists() {
        UserDefaults.standard.set(false, forKey: testKey)

        let service = UserDefaultsSettingsService()
        XCTAssertFalse(service.isNotificationsEnabled)

        service.isNotificationsEnabled = true

        let service2 = UserDefaultsSettingsService()
        XCTAssertTrue(service2.isNotificationsEnabled)
    }

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

    func test_mockService_notificationsToggle() {
        let mock = MockSettingsService()
        XCTAssertTrue(mock.isNotificationsEnabled)

        mock.isNotificationsEnabled = false
        XCTAssertFalse(mock.isNotificationsEnabled)
    }
}
