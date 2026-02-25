import Foundation

protocol BreedLogService {
    func buildBreedLog(from cats: [Cat]) -> [BreedLogEntry]
    func catsForBreed(_ breedName: String, from cats: [Cat]) -> [Cat]
}
