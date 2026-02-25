import Foundation
import Observation
import Vision
import os

@Observable
@MainActor
final class VisionBreedClassifierService: BreedClassifierService {
    private(set) var isClassifying = false

    private let logger = Logger(subsystem: "com.catch.catch", category: "BreedClassifier")

    func classify(imageData: Data) async -> [BreedPrediction] {
        isClassifying = true
        defer { isClassifying = false }

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let predictions = self.performClassification(imageData: imageData)
                continuation.resume(returning: predictions)
            }
        }
    }

    func classifyBest(imageDataArray: [Data]) async -> BreedPrediction? {
        guard !imageDataArray.isEmpty else { return nil }

        isClassifying = true
        defer { isClassifying = false }

        var best: BreedPrediction?
        for data in imageDataArray {
            let predictions = await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    let results = self.performClassification(imageData: data)
                    continuation.resume(returning: results)
                }
            }
            if let top = predictions.first,
               top.confidence > (best?.confidence ?? 0) {
                best = top
            }
        }
        return best
    }

    // MARK: - Private

    private nonisolated func performClassification(imageData: Data) -> [BreedPrediction] {
        #if DEBUG && targetEnvironment(simulator)
        return simulatorFallback()
        #else
        return visionClassification(imageData: imageData)
        #endif
    }

    private nonisolated func visionClassification(imageData: Data) -> [BreedPrediction] {
        let logger = Logger(subsystem: "com.catch.catch", category: "BreedClassifier")

        guard let handler = try? VNImageRequestHandler(data: imageData, options: [:]) else {
            logger.error("failed to create image request handler")
            return []
        }

        let request = VNClassifyImageRequest()
        do {
            try handler.perform([request])
        } catch {
            logger.error("vision classification failed: \(error.localizedDescription)")
            return []
        }

        guard let observations = request.results else { return [] }

        #if DEBUG
        let top = observations.filter { $0.confidence > 0.01 }.prefix(20)
        for obs in top {
            logger.debug("vision: \(obs.identifier) — \(String(format: "%.3f", obs.confidence))")
        }
        #endif

        return observations
            .compactMap { observation -> BreedPrediction? in
                guard BreedLabelMapper.isCatBreed(observation.identifier),
                      observation.confidence > 0.01,
                      let displayName = BreedLabelMapper.displayName(for: observation.identifier)
                else { return nil }

                return BreedPrediction(
                    breed: displayName,
                    rawIdentifier: observation.identifier,
                    confidence: observation.confidence
                )
            }
            .sorted { $0.confidence > $1.confidence }
    }

    #if DEBUG && targetEnvironment(simulator)
    private nonisolated func simulatorFallback() -> [BreedPrediction] {
        let breeds = ["Tabby", "Ragdoll", "Russian Blue", "Maine Coon", "Persian", "Siamese"]
        let pick = breeds.randomElement() ?? "Tabby"
        let confidence = Float.random(in: 0.55...0.92)
        return [BreedPrediction(breed: pick, rawIdentifier: "sim_fallback", confidence: confidence)]
    }
    #endif
}
