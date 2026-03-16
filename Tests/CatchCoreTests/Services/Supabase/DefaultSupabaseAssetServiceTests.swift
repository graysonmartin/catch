import XCTest
@testable import CatchCore

@MainActor
final class DefaultSupabaseAssetServiceTests: XCTestCase {

    private var sut: DefaultSupabaseAssetService!
    private var mockProvider: MockSupabaseClientProvider!

    override func setUp() {
        super.setUp()
        mockProvider = MockSupabaseClientProvider()
        sut = DefaultSupabaseAssetService(clientProvider: mockProvider)
    }

    override func tearDown() {
        sut = nil
        mockProvider = nil
        super.tearDown()
    }

    // MARK: - publicURL

    func testPublicURLIncludesBucketAndPath() {
        let url = sut.publicURL(bucket: .catPhotos, path: "user-1/photo.jpg")
        XCTAssertTrue(url.contains("cat-photos"))
        XCTAssertTrue(url.contains("user-1/photo.jpg"))
        XCTAssertTrue(url.contains("/storage/v1/object/public/"))
    }

    func testPublicURLForProfilePhotos() {
        let url = sut.publicURL(bucket: .profilePhotos, path: "abc/avatar.jpg")
        XCTAssertTrue(url.contains("profile-photos"))
        XCTAssertTrue(url.contains("abc/avatar.jpg"))
    }

    func testPublicURLForEncounterPhotos() {
        let url = sut.publicURL(bucket: .encounterPhotos, path: "owner/pic.jpg")
        XCTAssertTrue(url.contains("encounter-photos"))
        XCTAssertTrue(url.contains("owner/pic.jpg"))
    }

    func testPublicURLStartsWithConfigURL() {
        let url = sut.publicURL(bucket: .catPhotos, path: "test/path.jpg")
        let expectedPrefix = SupabaseConfig.url.absoluteString
        XCTAssertTrue(url.hasPrefix(expectedPrefix))
    }
}
