import Foundation

@MainActor
protocol SettingsService: Observable {
    var isNotificationsEnabled: Bool { get set }

    func appVersion() -> String
    func buildNumber() -> String
}
