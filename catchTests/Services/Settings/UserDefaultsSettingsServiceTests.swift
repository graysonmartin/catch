import XCTest
import CatchCore

@MainActor
final class UserDefaultsSettingsServiceTests: XCTestCase {

    private var suiteName: String!
    private var defaults: UserDefaults!
    private var sut: UserDefaultsSettingsService!

    override func setUp() {
        super.setUp()
        suiteName = "test.settings.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        sut = UserDefaultsSettingsService(defaults: defaults!)
    }

    override func tearDown() {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
        sut = nil
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    // MARK: - Default Values

    func test_defaultDisplayName_isEmpty() {
        XCTAssertEqual(sut.displayName, "")
    }

    func test_defaultNotifications_isEnabled() {
        XCTAssertTrue(sut.isNotificationsEnabled)
    }

    func test_defaultAppearanceMode_isSystem() {
        XCTAssertEqual(sut.appearanceMode, .system)
    }

    // MARK: - Persistence

    func test_setDisplayName_persistsToUserDefaults() {
        sut.displayName = "cat whisperer"

        let reloaded = UserDefaultsSettingsService(defaults: defaults)
        XCTAssertEqual(reloaded.displayName, "cat whisperer")
    }

    func test_setNotificationsEnabled_persistsToUserDefaults() {
        sut.isNotificationsEnabled = false

        let reloaded = UserDefaultsSettingsService(defaults: defaults)
        XCTAssertFalse(reloaded.isNotificationsEnabled)
    }

    func test_setAppearanceMode_persistsToUserDefaults() {
        sut.appearanceMode = .dark

        let reloaded = UserDefaultsSettingsService(defaults: defaults)
        XCTAssertEqual(reloaded.appearanceMode, .dark)
    }

    func test_setAppearanceModeToLight_persistsToUserDefaults() {
        sut.appearanceMode = .light

        let reloaded = UserDefaultsSettingsService(defaults: defaults)
        XCTAssertEqual(reloaded.appearanceMode, .light)
    }

    // MARK: - App Info

    func test_appVersion_returnsNonEmptyString() {
        // In test context, Bundle.main may not have the key, so we just verify it returns something
        XCTAssertFalse(sut.appVersion.isEmpty)
    }

    func test_buildNumber_returnsNonEmptyString() {
        XCTAssertFalse(sut.buildNumber.isEmpty)
    }

    // MARK: - Corrupt Data

    func test_corruptAppearanceMode_fallsBackToSystem() {
        defaults.set("neon_glow", forKey: "catch.settings.appearanceMode")

        let reloaded = UserDefaultsSettingsService(defaults: defaults)
        XCTAssertEqual(reloaded.appearanceMode, .system)
    }
}
