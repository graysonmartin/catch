import XCTest
@testable import CatchCore

@MainActor
final class MockLocationSearchServiceTests: XCTestCase {

    private var service: MockLocationSearchService!

    override func setUp() {
        super.setUp()
        service = MockLocationSearchService()
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    // MARK: - updateQuery

    func test_updateQuery_recordsCallAndReturnsStubbedSuggestions() {
        let suggestions = [
            LocationSearchResult(title: "Geneva", subtitle: "Switzerland"),
            LocationSearchResult(title: "Geneva", subtitle: "IL, United States")
        ]
        service.stubbedSuggestions = suggestions

        service.updateQuery("Geneva")

        XCTAssertEqual(service.updateQueryCalls, ["Geneva"])
        XCTAssertEqual(service.suggestions, suggestions)
    }

    func test_updateQuery_multipleCallsTracked() {
        service.updateQuery("Gen")
        service.updateQuery("Gene")
        service.updateQuery("Geneva")

        XCTAssertEqual(service.updateQueryCalls.count, 3)
        XCTAssertEqual(service.updateQueryCalls, ["Gen", "Gene", "Geneva"])
    }

    // MARK: - resolve

    func test_resolve_returnsStubbedLocation() async {
        let result = LocationSearchResult(title: "Geneva", subtitle: "Switzerland")
        let expected = Location(name: "Geneva, Switzerland", latitude: 46.2044, longitude: 6.1432)
        service.stubbedResolveResult = expected

        let resolved = await service.resolve(result)

        XCTAssertEqual(resolved, expected)
        XCTAssertEqual(service.resolveCalls.count, 1)
        XCTAssertEqual(service.resolveCalls.first, result)
    }

    func test_resolve_returnsNilWhenNotStubbed() async {
        let result = LocationSearchResult(title: "Nowhere", subtitle: "")
        let resolved = await service.resolve(result)
        XCTAssertNil(resolved)
    }

    // MARK: - clear

    func test_clear_clearsSuggestionsAndIncrementsCount() {
        service.stubbedSuggestions = [
            LocationSearchResult(title: "Test", subtitle: "Place")
        ]
        service.updateQuery("Test")
        XCTAssertFalse(service.suggestions.isEmpty)

        service.clear()

        XCTAssertTrue(service.suggestions.isEmpty)
        XCTAssertEqual(service.clearCallCount, 1)
    }

    func test_clear_multipleCalls() {
        service.clear()
        service.clear()
        service.clear()
        XCTAssertEqual(service.clearCallCount, 3)
    }

    // MARK: - reset

    func test_reset_clearsAllState() {
        service.stubbedSuggestions = [
            LocationSearchResult(title: "A", subtitle: "B")
        ]
        service.stubbedResolveResult = Location(name: "Test", latitude: 0, longitude: 0)
        service.updateQuery("test")
        service.clear()

        service.reset()

        XCTAssertTrue(service.updateQueryCalls.isEmpty)
        XCTAssertTrue(service.resolveCalls.isEmpty)
        XCTAssertEqual(service.clearCallCount, 0)
        XCTAssertTrue(service.suggestions.isEmpty)
        XCTAssertTrue(service.stubbedSuggestions.isEmpty)
        XCTAssertNil(service.stubbedResolveResult)
    }

    // MARK: - Initial state

    func test_initialState_isEmpty() {
        XCTAssertTrue(service.suggestions.isEmpty)
        XCTAssertFalse(service.isResolving)
        XCTAssertTrue(service.updateQueryCalls.isEmpty)
        XCTAssertTrue(service.resolveCalls.isEmpty)
        XCTAssertEqual(service.clearCallCount, 0)
    }
}
