import Foundation
import Observation
import CatchCore

@Observable
@MainActor
final class SettingsViewModel {

    // MARK: - Dependencies

    private var settingsService: any SettingsService
    private var authService: (any AuthService)?

    // MARK: - State

    var displayName: String {
        didSet { settingsService.displayName = displayName }
    }

    var isNotificationsEnabled: Bool {
        didSet { settingsService.isNotificationsEnabled = isNotificationsEnabled }
    }

    var appearanceMode: AppearanceMode {
        didSet { settingsService.appearanceMode = appearanceMode }
    }

    var appVersion: String { settingsService.appVersion }
    var buildNumber: String { settingsService.buildNumber }

    var isSignedIn: Bool {
        authService?.authState.isSignedIn ?? false
    }

    var versionDisplay: String {
        "\(appVersion) (\(buildNumber))"
    }

    // MARK: - Init

    init(settingsService: any SettingsService, authService: (any AuthService)? = nil) {
        self.settingsService = settingsService
        self.authService = authService
        self.displayName = settingsService.displayName
        self.isNotificationsEnabled = settingsService.isNotificationsEnabled
        self.appearanceMode = settingsService.appearanceMode
    }

    // MARK: - Actions

    func signOut() {
        authService?.signOut()
    }
}
