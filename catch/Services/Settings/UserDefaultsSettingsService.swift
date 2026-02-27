import Foundation
import Observation
import CatchCore

@Observable
@MainActor
final class UserDefaultsSettingsService: SettingsService {

    // MARK: - Keys

    private enum Keys {
        static let displayName = "catch.settings.displayName"
        static let isNotificationsEnabled = "catch.settings.notificationsEnabled"
        static let appearanceMode = "catch.settings.appearanceMode"
    }

    // MARK: - Storage

    private let defaults: UserDefaults

    // MARK: - Properties

    var displayName: String {
        didSet { defaults.set(displayName, forKey: Keys.displayName) }
    }

    var isNotificationsEnabled: Bool {
        didSet { defaults.set(isNotificationsEnabled, forKey: Keys.isNotificationsEnabled) }
    }

    var appearanceMode: AppearanceMode {
        didSet { defaults.set(appearanceMode.rawValue, forKey: Keys.appearanceMode) }
    }

    var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "???"
    }

    var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "???"
    }

    // MARK: - Init

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.displayName = defaults.string(forKey: Keys.displayName) ?? ""
        self.isNotificationsEnabled = defaults.object(forKey: Keys.isNotificationsEnabled) as? Bool ?? true
        let rawMode = defaults.string(forKey: Keys.appearanceMode) ?? AppearanceMode.system.rawValue
        self.appearanceMode = AppearanceMode(rawValue: rawMode) ?? .system
    }
}
