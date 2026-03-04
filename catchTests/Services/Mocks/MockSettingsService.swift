import Foundation
import Observation

@Observable
@MainActor
final class MockSettingsService: SettingsService {

    var isNotificationsEnabled: Bool = true
    var stubbedAppVersion: String = "1.0.0"
    var stubbedBuildNumber: String = "42"

    func appVersion() -> String {
        stubbedAppVersion
    }

    func buildNumber() -> String {
        stubbedBuildNumber
    }
}
