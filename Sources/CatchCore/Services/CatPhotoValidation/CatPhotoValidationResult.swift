import Foundation

/// The result of validating a single photo for cat presence.
public struct CatPhotoValidationResult: Sendable, Equatable {
    /// Whether a cat was detected with sufficient confidence.
    public let isCatDetected: Bool
    /// The highest confidence score for a "Cat" label, if any.
    public let confidence: Float
    /// Index of the photo in the array that was validated.
    public let photoIndex: Int

    public init(isCatDetected: Bool, confidence: Float, photoIndex: Int) {
        self.isCatDetected = isCatDetected
        self.confidence = confidence
        self.photoIndex = photoIndex
    }

    /// Convenience: result representing a photo where no cat was found.
    public static func noCat(at index: Int) -> CatPhotoValidationResult {
        CatPhotoValidationResult(isCatDetected: false, confidence: 0, photoIndex: index)
    }
}
