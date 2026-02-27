import Foundation
import Observation
import CatchCore

@Observable
@MainActor
final class MockBreedClassifierService: BreedClassifierService {
    private(set) var isClassifying = false

    private(set) var classifyCalls: [Data] = []
    private(set) var classifyBestCalls: [[Data]] = []

    var classifyResult: [BreedPrediction] = []
    var classifyBestResult: BreedPrediction?

    func classify(imageData: Data) async -> [BreedPrediction] {
        classifyCalls.append(imageData)
        return classifyResult
    }

    func classifyBest(imageDataArray: [Data]) async -> BreedPrediction? {
        classifyBestCalls.append(imageDataArray)
        return classifyBestResult
    }

    func reset() {
        classifyCalls = []
        classifyBestCalls = []
        classifyResult = []
        classifyBestResult = nil
    }
}
