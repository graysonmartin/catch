import XCTest

@MainActor
final class HapticCooldownTests: XCTestCase {

    // MARK: - canFire

    func testCanFire_returnsTrue_whenNeverFired() {
        let cooldown = HapticCooldown()
        XCTAssertTrue(cooldown.canFire(.light))
        XCTAssertTrue(cooldown.canFire(.medium))
        XCTAssertTrue(cooldown.canFire(.heavy))
        XCTAssertTrue(cooldown.canFire(.success))
        XCTAssertTrue(cooldown.canFire(.warning))
        XCTAssertTrue(cooldown.canFire(.selection))
    }

    func testCanFire_returnsFalse_immediatelyAfterFiring() {
        var cooldown = HapticCooldown()
        cooldown.recordFire(.medium)
        XCTAssertFalse(cooldown.canFire(.medium))
    }

    func testCanFire_allowsDifferentTypes_simultaneously() {
        var cooldown = HapticCooldown()
        cooldown.recordFire(.light)
        // Different type should still be allowed
        XCTAssertTrue(cooldown.canFire(.medium))
        XCTAssertTrue(cooldown.canFire(.success))
    }

    func testCanFire_returnsTrue_afterCooldownElapsed() async {
        var cooldown = HapticCooldown()
        cooldown.recordFire(.light)
        XCTAssertFalse(cooldown.canFire(.light))

        // Wait for cooldown to elapse
        try? await Task.sleep(for: .milliseconds(200))
        XCTAssertTrue(cooldown.canFire(.light))
    }

    // MARK: - reset

    func testReset_clearsAllFireTimes() {
        var cooldown = HapticCooldown()
        cooldown.recordFire(.light)
        cooldown.recordFire(.medium)
        cooldown.recordFire(.success)

        XCTAssertFalse(cooldown.canFire(.light))
        XCTAssertFalse(cooldown.canFire(.medium))
        XCTAssertFalse(cooldown.canFire(.success))

        cooldown.reset()

        XCTAssertTrue(cooldown.canFire(.light))
        XCTAssertTrue(cooldown.canFire(.medium))
        XCTAssertTrue(cooldown.canFire(.success))
    }

    // MARK: - Interval

    func testCooldownInterval_isReasonable() {
        // Should be between 50ms and 500ms — enough to debounce
        // without feeling sluggish
        XCTAssertGreaterThanOrEqual(HapticCooldown.interval, 0.05)
        XCTAssertLessThanOrEqual(HapticCooldown.interval, 0.5)
    }

    // MARK: - FeedbackType coverage

    func testAllFeedbackTypes_trackIndependently() {
        var cooldown = HapticCooldown()
        let allTypes: [HapticService.FeedbackType] = [
            .light, .medium, .heavy, .success, .warning, .selection
        ]

        // Fire all types
        for type in allTypes {
            cooldown.recordFire(type)
        }

        // All should be on cooldown
        for type in allTypes {
            XCTAssertFalse(cooldown.canFire(type), "\(type) should be on cooldown")
        }
    }
}
