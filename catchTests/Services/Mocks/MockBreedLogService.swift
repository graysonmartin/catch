import Foundation

final class MockBreedLogService: BreedLogService {

    private(set) var buildBreedLogCalls: [[Cat]] = []
    private(set) var buildBreedLogCloudCalls: [[CloudCat]] = []
    private(set) var catsForBreedCalls: [(breedName: String, cats: [Cat])] = []

    var buildBreedLogResult: [BreedLogEntry] = []
    var buildBreedLogCloudResult: [BreedLogEntry] = []
    var catsForBreedResult: [Cat] = []

    func buildBreedLog(from cats: [Cat]) -> [BreedLogEntry] {
        buildBreedLogCalls.append(cats)
        return buildBreedLogResult
    }

    func buildBreedLog(from cloudCats: [CloudCat]) -> [BreedLogEntry] {
        buildBreedLogCloudCalls.append(cloudCats)
        return buildBreedLogCloudResult
    }

    func catsForBreed(_ breedName: String, from cats: [Cat]) -> [Cat] {
        catsForBreedCalls.append((breedName, cats))
        return catsForBreedResult
    }

    func reset() {
        buildBreedLogCalls = []
        buildBreedLogCloudCalls = []
        catsForBreedCalls = []
        buildBreedLogResult = []
        buildBreedLogCloudResult = []
        catsForBreedResult = []
    }
}
