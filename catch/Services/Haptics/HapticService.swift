import UIKit

/// Centralized haptic feedback service with cooldown to prevent spam.
///
/// Uses pre-prepared `UIFeedbackGenerator` instances for responsive feedback.
/// All methods are safe to call from the main thread.
@MainActor
enum HapticService {

    // MARK: - Feedback Types

    enum FeedbackType: Hashable {
        /// Light tap — tab switches, selection changes, toggles, minor taps.
        case light
        /// Medium tap — like/unlike, follow/unfollow, primary button taps.
        case medium
        /// Heavy tap — reserved for emphasis (destructive confirms, etc.).
        case heavy
        /// Success notification — save completed, cat registered, encounter logged.
        case success
        /// Warning notification — validation error, action blocked.
        case warning
        /// Selection tick — scrolling pickers, sort option changes, filter toggles.
        case selection
    }

    // MARK: - Generators (lazy, prepared on first use)

    private static let lightGenerator: UIImpactFeedbackGenerator = {
        let g = UIImpactFeedbackGenerator(style: .light)
        g.prepare()
        return g
    }()

    private static let mediumGenerator: UIImpactFeedbackGenerator = {
        let g = UIImpactFeedbackGenerator(style: .medium)
        g.prepare()
        return g
    }()

    private static let heavyGenerator: UIImpactFeedbackGenerator = {
        let g = UIImpactFeedbackGenerator(style: .heavy)
        g.prepare()
        return g
    }()

    private static let notificationGenerator: UINotificationFeedbackGenerator = {
        let g = UINotificationFeedbackGenerator()
        g.prepare()
        return g
    }()

    private static let selectionGenerator: UISelectionFeedbackGenerator = {
        let g = UISelectionFeedbackGenerator()
        g.prepare()
        return g
    }()

    // MARK: - Cooldown

    private(set) static var cooldown = HapticCooldown()

    // MARK: - Public API

    /// Triggers haptic feedback of the given type, respecting cooldown.
    static func fire(_ type: FeedbackType) {
        guard cooldown.canFire(type) else { return }
        cooldown.recordFire(type)

        switch type {
        case .light:
            lightGenerator.impactOccurred()
            lightGenerator.prepare()
        case .medium:
            mediumGenerator.impactOccurred()
            mediumGenerator.prepare()
        case .heavy:
            heavyGenerator.impactOccurred()
            heavyGenerator.prepare()
        case .success:
            notificationGenerator.notificationOccurred(.success)
            notificationGenerator.prepare()
        case .warning:
            notificationGenerator.notificationOccurred(.warning)
            notificationGenerator.prepare()
        case .selection:
            selectionGenerator.selectionChanged()
            selectionGenerator.prepare()
        }
    }

    #if DEBUG
    /// Resets cooldown state for testing. DEBUG builds only.
    static func resetForTesting() {
        cooldown = HapticCooldown()
    }
    #endif
}

// MARK: - Cooldown Logic (Extracted for Testability)

/// Tracks per-type cooldown to prevent haptic spam on rapid repeated actions.
struct HapticCooldown {

    /// Minimum interval between haptic fires of the same type, in seconds.
    static let interval: TimeInterval = 0.15

    /// Tracks the last fire time per feedback type.
    private var lastFireTimes: [HapticService.FeedbackType: Date] = [:]

    /// Returns true if the cooldown has elapsed for the given type.
    func canFire(_ type: HapticService.FeedbackType) -> Bool {
        guard let last = lastFireTimes[type] else { return true }
        return Date().timeIntervalSince(last) >= Self.interval
    }

    /// Records that a haptic of the given type was just fired.
    mutating func recordFire(_ type: HapticService.FeedbackType) {
        lastFireTimes[type] = Date()
    }

    /// Resets all recorded fire times.
    mutating func reset() {
        lastFireTimes.removeAll()
    }
}
