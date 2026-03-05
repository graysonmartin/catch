import Foundation
import Observation
@testable import CatchCore

@Observable
@MainActor
final class MockLocationSearchService: LocationSearchService {
    private(set) var suggestions: [LocationSearchResult] = []
    private(set) var isResolving = false

    private(set) var updateQueryCalls: [String] = []
    private(set) var resolveCalls: [LocationSearchResult] = []
    private(set) var clearCallCount = 0

    var stubbedSuggestions: [LocationSearchResult] = []
    var stubbedResolveResult: Location?

    func updateQuery(_ fragment: String) {
        updateQueryCalls.append(fragment)
        suggestions = stubbedSuggestions
    }

    func resolve(_ result: LocationSearchResult) async -> Location? {
        resolveCalls.append(result)
        isResolving = true
        defer { isResolving = false }
        return stubbedResolveResult
    }

    func clear() {
        clearCallCount += 1
        suggestions = []
    }

    func reset() {
        updateQueryCalls = []
        resolveCalls = []
        clearCallCount = 0
        suggestions = []
        stubbedSuggestions = []
        stubbedResolveResult = nil
    }
}
