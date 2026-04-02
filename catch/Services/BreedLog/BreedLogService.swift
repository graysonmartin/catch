import Foundation
import CatchCore

protocol BreedLogService {
    func buildBreedLog(from cats: [Cat]) -> [BreedLogEntry]
    func buildBreedLog(from cloudCats: [CloudCat]) -> [BreedLogEntry]
    func catsForBreed(_ breedName: String, from cats: [Cat]) -> [Cat]
    func cloudCatsForBreed(_ breedName: String, from cats: [CloudCat]) -> [CloudCat]
}
