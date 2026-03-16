import XCTest
@testable import CatchCore

@MainActor
final class SupabaseAssetServiceTests: XCTestCase {

    private var sut: MockSupabaseAssetService!

    override func setUp() {
        super.setUp()
        sut = MockSupabaseAssetService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - uploadPhoto

    func testUploadPhotoRecordsCall() async throws {
        let data = Data([0xFF, 0xD8, 0xFF])
        _ = try await sut.uploadPhoto(data, bucket: .catPhotos, ownerID: "user-1", fileName: "photo.jpg")

        XCTAssertEqual(sut.uploadPhotoCalls.count, 1)
        XCTAssertEqual(sut.uploadPhotoCalls.first?.bucket, .catPhotos)
        XCTAssertEqual(sut.uploadPhotoCalls.first?.ownerID, "user-1")
        XCTAssertEqual(sut.uploadPhotoCalls.first?.fileName, "photo.jpg")
    }

    func testUploadPhotoReturnsURL() async throws {
        sut.uploadPhotoResult = "https://example.com/photo.jpg"
        let url = try await sut.uploadPhoto(Data(), bucket: .catPhotos, ownerID: "u", fileName: "f.jpg")
        XCTAssertEqual(url, "https://example.com/photo.jpg")
    }

    func testUploadPhotoThrowsOnError() async {
        sut.errorToThrow = NSError(domain: "test", code: 500)
        do {
            _ = try await sut.uploadPhoto(Data(), bucket: .catPhotos, ownerID: "u", fileName: "f.jpg")
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual((error as NSError).code, 500)
        }
    }

    // MARK: - uploadPhotos

    func testUploadPhotosRecordsCalls() async throws {
        let photos = [Data([1]), Data([2]), Data([3])]
        let urls = try await sut.uploadPhotos(photos, bucket: .encounterPhotos, ownerID: "owner-1")

        XCTAssertEqual(sut.uploadPhotosCalls.count, 1)
        XCTAssertEqual(sut.uploadPhotosCalls.first?.photos.count, 3)
        XCTAssertEqual(sut.uploadPhotosCalls.first?.bucket, .encounterPhotos)
        XCTAssertEqual(urls.count, 3)
    }

    func testUploadPhotosReturnsCustomResult() async throws {
        sut.uploadPhotosResult = ["url1", "url2"]
        let urls = try await sut.uploadPhotos([Data(), Data()], bucket: .catPhotos, ownerID: "o")
        XCTAssertEqual(urls, ["url1", "url2"])
    }

    // MARK: - deletePhoto

    func testDeletePhotoRecordsCall() async throws {
        try await sut.deletePhoto(bucket: .profilePhotos, path: "user-1/avatar.jpg")
        XCTAssertEqual(sut.deletePhotoCalls.count, 1)
        XCTAssertEqual(sut.deletePhotoCalls.first?.bucket, .profilePhotos)
        XCTAssertEqual(sut.deletePhotoCalls.first?.path, "user-1/avatar.jpg")
    }

    // MARK: - publicURL

    func testPublicURLBuildsCorrectPath() {
        let url = sut.publicURL(bucket: .catPhotos, path: "user-1/photo.jpg")
        XCTAssertEqual(url, "https://test.supabase.co/storage/v1/object/public/cat-photos/user-1/photo.jpg")
    }

    func testPublicURLRecordsCall() {
        _ = sut.publicURL(bucket: .encounterPhotos, path: "u/p.jpg")
        XCTAssertEqual(sut.publicURLCalls.count, 1)
    }

    // MARK: - reset

    func testResetClearsState() async throws {
        _ = try await sut.uploadPhoto(Data(), bucket: .catPhotos, ownerID: "u", fileName: "f")
        _ = sut.publicURL(bucket: .catPhotos, path: "p")
        sut.reset()

        XCTAssertTrue(sut.uploadPhotoCalls.isEmpty)
        XCTAssertTrue(sut.uploadPhotosCalls.isEmpty)
        XCTAssertTrue(sut.deletePhotoCalls.isEmpty)
        XCTAssertTrue(sut.publicURLCalls.isEmpty)
    }
}
