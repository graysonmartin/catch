import XCTest

final class BreedPredictionTests: XCTestCase {

    func test_equality_sameValuesAreEqual() {
        let a = BreedPrediction(breed: "Tabby", rawIdentifier: "tabby", confidence: 0.85)
        let b = BreedPrediction(breed: "Tabby", rawIdentifier: "tabby", confidence: 0.85)
        XCTAssertEqual(a, b)
    }

    func test_equality_differentBreedsAreNotEqual() {
        let a = BreedPrediction(breed: "Tabby", rawIdentifier: "tabby", confidence: 0.85)
        let b = BreedPrediction(breed: "Persian", rawIdentifier: "Persian_cat", confidence: 0.85)
        XCTAssertNotEqual(a, b)
    }

    func test_equality_differentConfidencesAreNotEqual() {
        let a = BreedPrediction(breed: "Tabby", rawIdentifier: "tabby", confidence: 0.85)
        let b = BreedPrediction(breed: "Tabby", rawIdentifier: "tabby", confidence: 0.50)
        XCTAssertNotEqual(a, b)
    }

    func test_properties_areStoredCorrectly() {
        let prediction = BreedPrediction(breed: "Maine Coon", rawIdentifier: "Maine_Coon", confidence: 0.92)
        XCTAssertEqual(prediction.breed, "Maine Coon")
        XCTAssertEqual(prediction.rawIdentifier, "Maine_Coon")
        XCTAssertEqual(prediction.confidence, 0.92, accuracy: 0.001)
    }
}
