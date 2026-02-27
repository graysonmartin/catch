import Foundation
import Observation
import Vision
import os
import CatchCore

@Observable
@MainActor
final class VisionCatPhotoValidationService: CatPhotoValidationService, @unchecked Sendable {
    private(set) var isValidating = false
    /// Per-photo validation results from the most recent batch.
    private(set) var results: [CatPhotoValidationResult] = []

    private let logger = Logger(subsystem: "com.catch.catch", category: "CatPhotoValidation")

    func validatePhoto(
        imageData: Data,
        photoIndex: Int,
        confidenceThreshold: Float
    ) async -> CatPhotoValidationResult {
        isValidating = true
        defer { isValidating = false }

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [logger] in
                let result = Self.performValidation(
                    imageData: imageData,
                    photoIndex: photoIndex,
                    confidenceThreshold: confidenceThreshold,
                    logger: logger
                )
                continuation.resume(returning: result)
            }
        }
    }

    func validatePhotos(
        imageDataArray: [Data],
        confidenceThreshold: Float
    ) async -> [CatPhotoValidationResult] {
        guard !imageDataArray.isEmpty else { return [] }

        isValidating = true
        defer { isValidating = false }

        var batchResults: [CatPhotoValidationResult] = []
        for (index, data) in imageDataArray.enumerated() {
            let result = await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async { [logger] in
                    let result = Self.performValidation(
                        imageData: data,
                        photoIndex: index,
                        confidenceThreshold: confidenceThreshold,
                        logger: logger
                    )
                    continuation.resume(returning: result)
                }
            }
            batchResults.append(result)
        }

        results = batchResults
        return batchResults
    }

    /// Clears stored results (e.g., when photos change).
    func clearResults() {
        results = []
    }

    // MARK: - Private

    private static func performValidation(
        imageData: Data,
        photoIndex: Int,
        confidenceThreshold: Float,
        logger: Logger
    ) -> CatPhotoValidationResult {
        guard let handler = try? VNImageRequestHandler(data: imageData, options: [:]) else {
            logger.error("failed to create image handler for photo \(photoIndex)")
            return .noCat(at: photoIndex)
        }

        let request = VNRecognizeAnimalsRequest()
        do {
            try handler.perform([request])
        } catch {
            logger.error("animal recognition failed for photo \(photoIndex): \(error.localizedDescription)")
            return .noCat(at: photoIndex)
        }

        guard let observations = request.results else {
            return .noCat(at: photoIndex)
        }

        // Find the best "Cat" label across all recognized animals
        var bestCatConfidence: Float = 0
        for observation in observations {
            for label in observation.labels where label.identifier == "Cat" {
                bestCatConfidence = max(bestCatConfidence, label.confidence)
            }
        }

        let isDetected = bestCatConfidence >= confidenceThreshold

        #if DEBUG
        logger.debug("photo \(photoIndex): cat confidence \(String(format: "%.3f", bestCatConfidence)), detected: \(isDetected)")
        #endif

        return CatPhotoValidationResult(
            isCatDetected: isDetected,
            confidence: bestCatConfidence,
            photoIndex: photoIndex
        )
    }
}
