import Foundation
import Observation

@Observable
@MainActor
final class UserDefaultsSettingsService: SettingsService {

    private static let notificationsKey = "catch.settings.notificationsEnabled"

    var isNotificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isNotificationsEnabled, forKey: Self.notificationsKey)
        }
    }

    init() {
        // Default to true if never set
        if UserDefaults.standard.object(forKey: Self.notificationsKey) == nil {
            self.isNotificationsEnabled = true
        } else {
            self.isNotificationsEnabled = UserDefaults.standard.bool(forKey: Self.notificationsKey)
        }
    }

    func appVersion() -> String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "???"
    }

    func buildNumber() -> String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "???"
    }
}
