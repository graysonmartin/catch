import Foundation

struct BreedPrediction: Sendable, Equatable {
    let breed: String
    let rawIdentifier: String
    let confidence: Float
}
