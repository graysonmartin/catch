import Foundation
@testable import CatchCore

final class MockCatPhotoValidationService: CatPhotoValidationService {

    private(set) var validatePhotoCalls: [(Data, Int, Float)] = []
    private(set) var validatePhotosCalls: [([Data], Float)] = []

    var validatePhotoResult: CatPhotoValidationResult = .noCat(at: 0)
    var validatePhotosResult: [CatPhotoValidationResult] = []

    func validatePhoto(
        imageData: Data,
        photoIndex: Int,
        confidenceThreshold: Float
    ) async -> CatPhotoValidationResult {
        validatePhotoCalls.append((imageData, photoIndex, confidenceThreshold))
        return validatePhotoResult
    }

    func validatePhotos(
        imageDataArray: [Data],
        confidenceThreshold: Float
    ) async -> [CatPhotoValidationResult] {
        validatePhotosCalls.append((imageDataArray, confidenceThreshold))
        return validatePhotosResult
    }

    func reset() {
        validatePhotoCalls = []
        validatePhotosCalls = []
        validatePhotoResult = .noCat(at: 0)
        validatePhotosResult = []
    }
}
