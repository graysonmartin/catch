import Foundation

public struct BreedPrediction: Sendable, Equatable {
    public let breed: String
    public let rawIdentifier: String
    public let confidence: Float

    public init(breed: String, rawIdentifier: String, confidence: Float) {
        self.breed = breed
        self.rawIdentifier = rawIdentifier
        self.confidence = confidence
    }
}
