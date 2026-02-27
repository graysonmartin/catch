import XCTest
@testable import CatchCore

final class CatPhotoValidationResultTests: XCTestCase {

    // MARK: - Init

    func test_init_storesProperties() {
        let result = CatPhotoValidationResult(
            isCatDetected: true,
            confidence: 0.85,
            photoIndex: 2
        )
        XCTAssertTrue(result.isCatDetected)
        XCTAssertEqual(result.confidence, 0.85, accuracy: 0.001)
        XCTAssertEqual(result.photoIndex, 2)
    }

    func test_init_noCatDetected() {
        let result = CatPhotoValidationResult(
            isCatDetected: false,
            confidence: 0.1,
            photoIndex: 0
        )
        XCTAssertFalse(result.isCatDetected)
        XCTAssertEqual(result.confidence, 0.1, accuracy: 0.001)
    }

    // MARK: - Equatable

    func test_equality_sameValuesAreEqual() {
        let a = CatPhotoValidationResult(isCatDetected: true, confidence: 0.9, photoIndex: 1)
        let b = CatPhotoValidationResult(isCatDetected: true, confidence: 0.9, photoIndex: 1)
        XCTAssertEqual(a, b)
    }

    func test_equality_differentDetectionAreNotEqual() {
        let a = CatPhotoValidationResult(isCatDetected: true, confidence: 0.9, photoIndex: 1)
        let b = CatPhotoValidationResult(isCatDetected: false, confidence: 0.9, photoIndex: 1)
        XCTAssertNotEqual(a, b)
    }

    func test_equality_differentConfidenceAreNotEqual() {
        let a = CatPhotoValidationResult(isCatDetected: true, confidence: 0.9, photoIndex: 1)
        let b = CatPhotoValidationResult(isCatDetected: true, confidence: 0.5, photoIndex: 1)
        XCTAssertNotEqual(a, b)
    }

    func test_equality_differentIndexAreNotEqual() {
        let a = CatPhotoValidationResult(isCatDetected: true, confidence: 0.9, photoIndex: 0)
        let b = CatPhotoValidationResult(isCatDetected: true, confidence: 0.9, photoIndex: 3)
        XCTAssertNotEqual(a, b)
    }

    // MARK: - Factory

    func test_noCat_factoryMethod() {
        let result = CatPhotoValidationResult.noCat(at: 5)
        XCTAssertFalse(result.isCatDetected)
        XCTAssertEqual(result.confidence, 0, accuracy: 0.001)
        XCTAssertEqual(result.photoIndex, 5)
    }

    func test_noCat_atZeroIndex() {
        let result = CatPhotoValidationResult.noCat(at: 0)
        XCTAssertEqual(result.photoIndex, 0)
        XCTAssertFalse(result.isCatDetected)
    }
}
