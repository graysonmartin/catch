import XCTest
import SwiftData

@MainActor
final class PersonalityLabelTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() async throws {
        container = try ModelContainer.forTesting()
        context = container.mainContext
    }

    override func tearDown() async throws {
        container = nil
        context = nil
    }

    // MARK: - PersonalityLabel enum

    func test_allCasesCount() {
        XCTAssertEqual(PersonalityLabel.allCases.count, 21)
    }

    func test_standardLabelsCount() {
        XCTAssertEqual(PersonalityLabel.standard.count, 8)
    }

    func test_weirdLabelsCount() {
        XCTAssertEqual(PersonalityLabel.weird.count, 13)
    }

    func test_standardAndWeirdCoverAllCases() {
        let combined = Set(PersonalityLabel.standard + PersonalityLabel.weird)
        let allCases = Set(PersonalityLabel.allCases)
        XCTAssertEqual(combined, allCases)
    }

    func test_displayNameMatchesRawValue() {
        for label in PersonalityLabel.allCases {
            XCTAssertEqual(label.displayName, label.rawValue)
        }
    }

    func test_multiWordLabelsHaveSpaces() {
        XCTAssertEqual(PersonalityLabel.suspiciouslyPolite.displayName, "suspiciously polite")
        XCTAssertEqual(PersonalityLabel.oneBrainCell.displayName, "one brain cell")
        XCTAssertEqual(PersonalityLabel.wouldCommitCrimes.displayName, "would commit crimes")
    }

    func test_identifiableConformance() {
        let label = PersonalityLabel.haunted
        XCTAssertEqual(label.id, "haunted")
    }

    // MARK: - Cat personality labels persistence

    func test_catDefaultsToEmptyLabels() {
        let cat = Cat(name: "Test")
        XCTAssertTrue(cat.personalityLabels.isEmpty)
    }

    func test_catWithLabels_initSetsLabels() {
        let cat = Cat(name: "Chaotic", personalityLabels: ["chaotic", "menace"])
        XCTAssertEqual(cat.personalityLabels, ["chaotic", "menace"])
    }

    func test_catPersonalityLabels_persistAndFetch() throws {
        let labels = ["silly", "haunted", "large"]
        let cat = Fixtures.cat(name: "Labeled", personalityLabels: labels, in: context)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Cat>())
        XCTAssertEqual(fetched.first?.personalityLabels, labels)
        XCTAssertEqual(fetched.first?.name, cat.name)
    }

    func test_catPersonalityLabels_canBeUpdated() throws {
        let cat = Fixtures.cat(name: "Evolving", personalityLabels: ["shy"], in: context)
        try context.save()

        cat.personalityLabels = ["shy", "plotting something", "built different"]
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Cat>())
        XCTAssertEqual(fetched.first?.personalityLabels.count, 3)
        XCTAssertTrue(fetched.first?.personalityLabels.contains("plotting something") ?? false)
    }

    func test_catPersonalityLabels_canBeCleared() throws {
        let cat = Fixtures.cat(name: "Reset", personalityLabels: ["chaotic", "soggy"], in: context)
        try context.save()

        cat.personalityLabels = []
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Cat>())
        XCTAssertTrue(fetched.first?.personalityLabels.isEmpty ?? false)
    }

    func test_catPersonalityLabels_emptyByDefaultInFixture() throws {
        _ = Fixtures.cat(name: "Default", in: context)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Cat>())
        XCTAssertTrue(fetched.first?.personalityLabels.isEmpty ?? false)
    }
}
