import Foundation

protocol BreedClassifierService: AnyObject {
    var isClassifying: Bool { get }
    func classify(imageData: Data) async -> [BreedPrediction]
    func classifyBest(imageDataArray: [Data]) async -> BreedPrediction?
}
