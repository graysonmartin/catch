import Foundation

/// Abstraction over the system clock for testability.
public protocol RateLimiterClock: Sendable {
    func now() -> Date
}

/// Uses the real system clock.
public struct SystemClock: RateLimiterClock {
    public init() {}

    public func now() -> Date {
        Date()
    }
}

/// A controllable clock for testing rate limiter behavior.
public final class MockClock: RateLimiterClock, @unchecked Sendable {
    private let lock = NSLock()
    private var currentDate: Date

    public init(now: Date = Date()) {
        self.currentDate = now
    }

    public func now() -> Date {
        lock.lock()
        defer { lock.unlock() }
        return currentDate
    }

    /// Advance the clock by the given interval.
    public func advance(by interval: TimeInterval) {
        lock.lock()
        defer { lock.unlock() }
        currentDate = currentDate.addingTimeInterval(interval)
    }

    /// Set the clock to a specific date.
    public func set(to date: Date) {
        lock.lock()
        defer { lock.unlock() }
        currentDate = date
    }
}
