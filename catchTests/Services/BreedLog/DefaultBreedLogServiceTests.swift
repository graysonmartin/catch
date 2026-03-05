import XCTest
import SwiftData
import CatchCore

@MainActor
final class DefaultBreedLogServiceTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!
    private var service: DefaultBreedLogService!

    override func setUp() {
        super.setUp()
        container = try! ModelContainer.forTesting()
        context = container.mainContext
        service = DefaultBreedLogService()
    }

    override func tearDown() {
        container = nil
        context = nil
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
        let cat = Fixtures.cat(name: "Luna", breed: "Ragdoll", in: context)
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
        let cat1 = Fixtures.cat(name: "Luna", breed: "Domestic Shorthair", in: context)
        let cat2 = Fixtures.cat(name: "Milo", breed: "Domestic Shorthair", in: context)

        let log = service.buildBreedLog(from: [cat1, cat2])
        let dsh = log.first { $0.id == "Domestic Shorthair" }
        XCTAssertEqual(dsh?.catCount, 2)
        XCTAssertTrue(dsh?.isDiscovered == true)
    }

    func test_buildBreedLog_customBreedIgnored() {
        let cat = Fixtures.cat(name: "Ziggy", breed: "Space Cat", in: context)
        let log = service.buildBreedLog(from: [cat])
        XCTAssertTrue(log.allSatisfy { !$0.isDiscovered })
    }

    func test_buildBreedLog_nilBreedIgnored() {
        let cat = Fixtures.cat(name: "Unknown", breed: nil, in: context)
        let log = service.buildBreedLog(from: [cat])
        XCTAssertTrue(log.allSatisfy { !$0.isDiscovered })
    }

    func test_buildBreedLog_multipleBreeds() {
        let cat1 = Fixtures.cat(name: "Luna", breed: "Ragdoll", in: context)
        let cat2 = Fixtures.cat(name: "Shadow", breed: "Bombay", in: context)
        let cat3 = Fixtures.cat(name: "Blue", breed: "Russian Blue", in: context)

        let log = service.buildBreedLog(from: [cat1, cat2, cat3])
        let discoveredCount = log.filter(\.isDiscovered).count
        XCTAssertEqual(discoveredCount, 3)
    }

    func test_buildBreedLog_firstDiscoveredDateIsEarliest() {
        let earlier = Date(timeIntervalSince1970: 1_000_000)
        let later = Date(timeIntervalSince1970: 2_000_000)

        let cat1 = Cat(name: "Old", breed: "Siamese")
        cat1.createdAt = earlier
        context.insert(cat1)

        let cat2 = Cat(name: "New", breed: "Siamese")
        cat2.createdAt = later
        context.insert(cat2)

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
        let cat1 = Fixtures.cat(name: "Luna", breed: "Bengal", in: context)
        let _ = Fixtures.cat(name: "Shadow", breed: "Bombay", in: context)
        let cat3 = Fixtures.cat(name: "Stripe", breed: "Bengal", in: context)

        let bengals = service.catsForBreed("Bengal", from: [cat1, cat3])
        XCTAssertEqual(bengals.count, 2)
    }

    func test_catsForBreed_noMatches_returnsEmpty() {
        let cat = Fixtures.cat(name: "Luna", breed: "Bengal", in: context)
        let result = service.catsForBreed("Sphynx", from: [cat])
        XCTAssertTrue(result.isEmpty)
    }

    func test_catsForBreed_sortedByCreatedAt() {
        let earlier = Date(timeIntervalSince1970: 1_000_000)
        let later = Date(timeIntervalSince1970: 2_000_000)

        let cat1 = Cat(name: "New", breed: "Domestic Shorthair")
        cat1.createdAt = later
        context.insert(cat1)

        let cat2 = Cat(name: "Old", breed: "Domestic Shorthair")
        cat2.createdAt = earlier
        context.insert(cat2)

        let result = service.catsForBreed("Domestic Shorthair", from: [cat1, cat2])
        XCTAssertEqual(result.first?.name, "Old")
        XCTAssertEqual(result.last?.name, "New")
    }
}
