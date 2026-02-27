import XCTest
import CatchCore

@MainActor
final class SettingsViewModelTests: XCTestCase {

    private var mockSettings: MockSettingsService!
    private var mockAuth: MockAuthService!
    private var sut: SettingsViewModel!

    override func setUp() {
        super.setUp()
        mockSettings = MockSettingsService()
        mockAuth = MockAuthService()
        sut = SettingsViewModel(settingsService: mockSettings, authService: mockAuth)
    }

    override func tearDown() {
        sut = nil
        mockAuth = nil
        mockSettings = nil
        super.tearDown()
    }

    // MARK: - Init

    func test_init_loadsDisplayNameFromService() {
        mockSettings.displayName = "steven fan"
        let vm = SettingsViewModel(settingsService: mockSettings)
        XCTAssertEqual(vm.displayName, "steven fan")
    }

    func test_init_loadsNotificationsFromService() {
        mockSettings.isNotificationsEnabled = false
        let vm = SettingsViewModel(settingsService: mockSettings)
        XCTAssertFalse(vm.isNotificationsEnabled)
    }

    func test_init_loadsAppearanceModeFromService() {
        mockSettings.appearanceMode = .dark
        let vm = SettingsViewModel(settingsService: mockSettings)
        XCTAssertEqual(vm.appearanceMode, .dark)
    }

    // MARK: - Display Name

    func test_setDisplayName_updatesService() {
        sut.displayName = "new name"
        XCTAssertEqual(mockSettings.displayName, "new name")
    }

    // MARK: - Notifications

    func test_setNotifications_updatesService() {
        sut.isNotificationsEnabled = false
        XCTAssertFalse(mockSettings.isNotificationsEnabled)
    }

    // MARK: - Appearance

    func test_setAppearanceMode_updatesService() {
        sut.appearanceMode = .light
        XCTAssertEqual(mockSettings.appearanceMode, .light)
    }

    // MARK: - Version

    func test_versionDisplay_combinesVersionAndBuild() {
        XCTAssertEqual(sut.versionDisplay, "1.0.0 (42)")
    }

    // MARK: - Auth State

    func test_isSignedIn_whenSignedOut_returnsFalse() {
        XCTAssertFalse(sut.isSignedIn)
    }

    func test_isSignedIn_whenSignedIn_returnsTrue() {
        mockAuth.simulateSignIn()
        // Need to re-create VM to pick up the state change through the property
        sut = SettingsViewModel(settingsService: mockSettings, authService: mockAuth)
        XCTAssertTrue(sut.isSignedIn)
    }

    func test_isSignedIn_withNoAuthService_returnsFalse() {
        let vm = SettingsViewModel(settingsService: mockSettings, authService: nil)
        XCTAssertFalse(vm.isSignedIn)
    }

    // MARK: - Sign Out

    func test_signOut_callsAuthServiceSignOut() {
        mockAuth.simulateSignIn()
        sut = SettingsViewModel(settingsService: mockSettings, authService: mockAuth)
        sut.signOut()
        XCTAssertTrue(mockAuth.signOutCalled)
    }

    func test_signOut_withNoAuthService_doesNotCrash() {
        let vm = SettingsViewModel(settingsService: mockSettings, authService: nil)
        vm.signOut() // Should not crash
    }
}
