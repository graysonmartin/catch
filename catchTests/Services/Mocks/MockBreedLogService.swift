import Foundation
import CatchCore

final class MockBreedLogService: BreedLogService {

    private(set) var buildBreedLogCalls: [[Cat]] = []
    private(set) var buildBreedLogCloudCalls: [[CloudCat]] = []
    private(set) var catsForBreedCalls: [(breedName: String, cats: [Cat])] = []
    private(set) var cloudCatsForBreedCalls: [(breedName: String, cats: [CloudCat])] = []

    var buildBreedLogResult: [BreedLogEntry] = []
    var buildBreedLogCloudResult: [BreedLogEntry] = []
    var catsForBreedResult: [Cat] = []
    var cloudCatsForBreedResult: [CloudCat] = []

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

    func cloudCatsForBreed(_ breedName: String, from cats: [CloudCat]) -> [CloudCat] {
        cloudCatsForBreedCalls.append((breedName, cats))
        return cloudCatsForBreedResult
    }

    func reset() {
        buildBreedLogCalls = []
        buildBreedLogCloudCalls = []
        catsForBreedCalls = []
        cloudCatsForBreedCalls = []
        buildBreedLogResult = []
        buildBreedLogCloudResult = []
        catsForBreedResult = []
        cloudCatsForBreedResult = []
    }
}
