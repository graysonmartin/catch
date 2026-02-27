import Foundation

@MainActor
public protocol SettingsService: Observable {
    var displayName: String { get set }
    var isNotificationsEnabled: Bool { get set }
    var appearanceMode: AppearanceMode { get set }
    var appVersion: String { get }
    var buildNumber: String { get }
}
