import Foundation
import Observation

@Observable
@MainActor
final class UserDefaultsSettingsService: SettingsService {

    func appVersion() -> String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "???"
    }

    func buildNumber() -> String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "???"
    }
}
