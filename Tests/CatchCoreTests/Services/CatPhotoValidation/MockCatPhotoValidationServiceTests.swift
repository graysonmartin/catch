import XCTest
@testable import CatchCore

final class MockCatPhotoValidationServiceTests: XCTestCase {

    private var sut: MockCatPhotoValidationService!

    override func setUp() {
        super.setUp()
        sut = MockCatPhotoValidationService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - validatePhoto

    func test_validatePhoto_recordsCall() async {
        let data = Data([0x01, 0x02, 0x03])
        _ = await sut.validatePhoto(imageData: data, photoIndex: 2, confidenceThreshold: 0.7)

        XCTAssertEqual(sut.validatePhotoCalls.count, 1)
        XCTAssertEqual(sut.validatePhotoCalls[0].0, data)
        XCTAssertEqual(sut.validatePhotoCalls[0].1, 2)
        XCTAssertEqual(sut.validatePhotoCalls[0].2, 0.7, accuracy: 0.001)
    }

    func test_validatePhoto_returnsConfiguredResult() async {
        let expected = CatPhotoValidationResult(isCatDetected: true, confidence: 0.95, photoIndex: 0)
        sut.validatePhotoResult = expected

        let result = await sut.validatePhoto(imageData: Data(), photoIndex: 0, confidenceThreshold: 0.5)
        XCTAssertEqual(result, expected)
    }

    // MARK: - validatePhotos

    func test_validatePhotos_recordsCall() async {
        let photos = [Data([0x01]), Data([0x02])]
        _ = await sut.validatePhotos(imageDataArray: photos, confidenceThreshold: 0.6)

        XCTAssertEqual(sut.validatePhotosCalls.count, 1)
        XCTAssertEqual(sut.validatePhotosCalls[0].0.count, 2)
        XCTAssertEqual(sut.validatePhotosCalls[0].1, 0.6, accuracy: 0.001)
    }

    func test_validatePhotos_returnsConfiguredResults() async {
        let expected = [
            CatPhotoValidationResult(isCatDetected: true, confidence: 0.9, photoIndex: 0),
            CatPhotoValidationResult(isCatDetected: false, confidence: 0.2, photoIndex: 1)
        ]
        sut.validatePhotosResult = expected

        let results = await sut.validatePhotos(imageDataArray: [Data(), Data()], confidenceThreshold: 0.5)
        XCTAssertEqual(results, expected)
    }

    func test_validatePhotos_emptyArrayReturnsEmpty() async {
        sut.validatePhotosResult = []
        let results = await sut.validatePhotos(imageDataArray: [], confidenceThreshold: 0.5)
        XCTAssertTrue(results.isEmpty)
    }

    // MARK: - Reset

    func test_reset_clearsState() async {
        _ = await sut.validatePhoto(imageData: Data(), photoIndex: 0, confidenceThreshold: 0.5)
        _ = await sut.validatePhotos(imageDataArray: [Data()], confidenceThreshold: 0.5)
        sut.validatePhotoResult = CatPhotoValidationResult(isCatDetected: true, confidence: 1.0, photoIndex: 0)
        sut.validatePhotosResult = [CatPhotoValidationResult(isCatDetected: true, confidence: 1.0, photoIndex: 0)]

        sut.reset()

        XCTAssertTrue(sut.validatePhotoCalls.isEmpty)
        XCTAssertTrue(sut.validatePhotosCalls.isEmpty)
        XCTAssertFalse(sut.validatePhotoResult.isCatDetected)
        XCTAssertTrue(sut.validatePhotosResult.isEmpty)
    }

    // MARK: - Default threshold

    func test_defaultConfidenceThreshold_isFiftyPercent() {
        XCTAssertEqual(MockCatPhotoValidationService.defaultConfidenceThreshold, 0.5, accuracy: 0.001)
    }

    // MARK: - Protocol default convenience methods

    func test_validatePhoto_defaultThreshold_usesHalf() async {
        _ = await sut.validatePhoto(imageData: Data(), photoIndex: 0)
        XCTAssertEqual(sut.validatePhotoCalls.count, 1)
        XCTAssertEqual(sut.validatePhotoCalls[0].2, 0.5, accuracy: 0.001)
    }

    func test_validatePhotos_defaultThreshold_usesHalf() async {
        _ = await sut.validatePhotos(imageDataArray: [Data()])
        XCTAssertEqual(sut.validatePhotosCalls.count, 1)
        XCTAssertEqual(sut.validatePhotosCalls[0].1, 0.5, accuracy: 0.001)
    }
}
