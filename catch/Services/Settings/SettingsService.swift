import Foundation

@MainActor
protocol SettingsService: Observable {
    func appVersion() -> String
    func buildNumber() -> String
}
