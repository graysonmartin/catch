import Foundation
import Observation
import CatchCore

@Observable
@MainActor
final class MockSettingsService: SettingsService {
    var displayName: String = ""
    var isNotificationsEnabled: Bool = true
    var appearanceMode: AppearanceMode = .system
    var appVersion: String = "1.0.0"
    var buildNumber: String = "42"
}
