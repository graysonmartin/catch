import XCTest
import CatchCore

@MainActor
final class DefaultBreedLogServiceTests: XCTestCase {

    private var service: DefaultBreedLogService!

    override func setUp() {
        super.setUp()
        service = DefaultBreedLogService()
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    // MARK: - buildBreedLog

    func test_buildBreedLog_emptyCats_returnsAllUndiscovered() {
        let log = service.buildBreedLog(from: [Cat]())
        XCTAssertEqual(log.count, 12)
        XCTAssertTrue(log.allSatisfy { !$0.isDiscovered })
        XCTAssertTrue(log.allSatisfy { $0.catCount == 0 })
        XCTAssertTrue(log.allSatisfy { $0.firstDiscoveredDate == nil })
    }

    func test_buildBreedLog_singleDiscoveredBreed() {
        let cat = Fixtures.cat(name: "Luna", breed: "Ragdoll")
        let log = service.buildBreedLog(from: [cat])

        let ragdoll = log.first { $0.id == "Ragdoll" }
        XCTAssertNotNil(ragdoll)
        XCTAssertTrue(ragdoll!.isDiscovered)
        XCTAssertEqual(ragdoll!.catCount, 1)
        XCTAssertNotNil(ragdoll!.firstDiscoveredDate)

        let undiscoveredCount = log.filter { !$0.isDiscovered }.count
        XCTAssertEqual(undiscoveredCount, 11)
    }

    func test_buildBreedLog_multipleCatsSameBreed() {
        let cat1 = Fixtures.cat(name: "Luna", breed: "Domestic Shorthair")
        let cat2 = Fixtures.cat(name: "Milo", breed: "Domestic Shorthair")

        let log = service.buildBreedLog(from: [cat1, cat2])
        let dsh = log.first { $0.id == "Domestic Shorthair" }
        XCTAssertEqual(dsh?.catCount, 2)
        XCTAssertTrue(dsh?.isDiscovered == true)
    }

    func test_buildBreedLog_customBreedIgnored() {
        let cat = Fixtures.cat(name: "Ziggy", breed: "Space Cat")
        let log = service.buildBreedLog(from: [cat])
        XCTAssertTrue(log.allSatisfy { !$0.isDiscovered })
    }

    func test_buildBreedLog_nilBreedIgnored() {
        let cat = Fixtures.cat(name: "Unknown", breed: nil)
        let log = service.buildBreedLog(from: [cat])
        XCTAssertTrue(log.allSatisfy { !$0.isDiscovered })
    }

    func test_buildBreedLog_multipleBreeds() {
        let cat1 = Fixtures.cat(name: "Luna", breed: "Ragdoll")
        let cat2 = Fixtures.cat(name: "Shadow", breed: "Bombay")
        let cat3 = Fixtures.cat(name: "Blue", breed: "Russian Blue")

        let log = service.buildBreedLog(from: [cat1, cat2, cat3])
        let discoveredCount = log.filter(\.isDiscovered).count
        XCTAssertEqual(discoveredCount, 3)
    }

    func test_buildBreedLog_firstDiscoveredDateIsEarliest() {
        let earlier = Date(timeIntervalSince1970: 1_000_000)
        let later = Date(timeIntervalSince1970: 2_000_000)

        let cat1 = Cat(name: "Old", breed: "Siamese", createdAt: earlier)
        let cat2 = Cat(name: "New", breed: "Siamese", createdAt: later)

        let log = service.buildBreedLog(from: [cat1, cat2])
        let siamese = log.first { $0.id == "Siamese" }
        XCTAssertEqual(siamese?.firstDiscoveredDate, earlier)
    }

    func test_buildBreedLog_returnsAll12Entries() {
        let log = service.buildBreedLog(from: [Cat]())
        XCTAssertEqual(log.count, BreedCatalog.count)
    }

    // MARK: - catsForBreed

    func test_catsForBreed_returnsMatchingCats() {
        let cat1 = Fixtures.cat(name: "Luna", breed: "Bengal")
        let cat3 = Fixtures.cat(name: "Stripe", breed: "Bengal")

        let bengals = service.catsForBreed("Bengal", from: [cat1, cat3])
        XCTAssertEqual(bengals.count, 2)
    }

    func test_catsForBreed_noMatches_returnsEmpty() {
        let cat = Fixtures.cat(name: "Luna", breed: "Bengal")
        let result = service.catsForBreed("Sphynx", from: [cat])
        XCTAssertTrue(result.isEmpty)
    }

    func test_catsForBreed_sortedByCreatedAt() {
        let earlier = Date(timeIntervalSince1970: 1_000_000)
        let later = Date(timeIntervalSince1970: 2_000_000)

        let cat1 = Cat(name: "New", breed: "Domestic Shorthair", createdAt: later)
        let cat2 = Cat(name: "Old", breed: "Domestic Shorthair", createdAt: earlier)

        let result = service.catsForBreed("Domestic Shorthair", from: [cat1, cat2])
        XCTAssertEqual(result.first?.name, "Old")
        XCTAssertEqual(result.last?.name, "New")
    }
}
