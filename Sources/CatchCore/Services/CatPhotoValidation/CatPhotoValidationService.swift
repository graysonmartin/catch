import Foundation

/// Protocol for validating whether photos contain a cat.
public protocol CatPhotoValidationService: AnyObject, Sendable {
    /// The default confidence threshold for considering a cat detected.
    static var defaultConfidenceThreshold: Float { get }

    /// Validate a single photo for cat presence.
    /// - Parameters:
    ///   - imageData: JPEG image data to validate.
    ///   - photoIndex: Index of this photo in the parent array.
    ///   - confidenceThreshold: Minimum confidence to consider a cat detected.
    /// - Returns: Validation result for this photo.
    func validatePhoto(
        imageData: Data,
        photoIndex: Int,
        confidenceThreshold: Float
    ) async -> CatPhotoValidationResult

    /// Validate multiple photos for cat presence.
    /// - Parameters:
    ///   - imageDataArray: Array of JPEG image data.
    ///   - confidenceThreshold: Minimum confidence to consider a cat detected.
    /// - Returns: Array of validation results, one per photo.
    func validatePhotos(
        imageDataArray: [Data],
        confidenceThreshold: Float
    ) async -> [CatPhotoValidationResult]
}

// MARK: - Default threshold

extension CatPhotoValidationService {

    public static var defaultConfidenceThreshold: Float { 0.5 }

    public func validatePhoto(
        imageData: Data,
        photoIndex: Int
    ) async -> CatPhotoValidationResult {
        await validatePhoto(
            imageData: imageData,
            photoIndex: photoIndex,
            confidenceThreshold: Self.defaultConfidenceThreshold
        )
    }

    public func validatePhotos(
        imageDataArray: [Data]
    ) async -> [CatPhotoValidationResult] {
        await validatePhotos(
            imageDataArray: imageDataArray,
            confidenceThreshold: Self.defaultConfidenceThreshold
        )
    }
}
