import XCTest
@testable import CatchCore

final class SupabaseStorageBucketTests: XCTestCase {

    func testProfilePhotosBucketName() {
        XCTAssertEqual(SupabaseStorageBucket.profilePhotos.rawValue, "profile-photos")
    }

    func testCatPhotosBucketName() {
        XCTAssertEqual(SupabaseStorageBucket.catPhotos.rawValue, "cat-photos")
    }

    func testEncounterPhotosBucketName() {
        XCTAssertEqual(SupabaseStorageBucket.encounterPhotos.rawValue, "encounter-photos")
    }
}
