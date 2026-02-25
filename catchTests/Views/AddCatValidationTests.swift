import XCTest

final class AddCatValidationTests: XCTestCase {

    // Mirrors the `canSave` logic in AddCatView:
    // !name.trimmingCharacters(in: .whitespaces).isEmpty && !photos.isEmpty
    private func canSave(name: String, photos: [Data]) -> Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !photos.isEmpty
    }

    private let fakePhoto = Data([0xFF, 0xD8, 0xFF])

    // MARK: - Valid states

    func testCanSaveWithNameAndPhoto() {
        XCTAssertTrue(canSave(name: "Muffin", photos: [fakePhoto]))
    }

    func testCanSaveWithMultiplePhotos() {
        XCTAssertTrue(canSave(name: "Biscuit", photos: [fakePhoto, fakePhoto]))
    }

    // MARK: - Missing photos

    func testCannotSaveWithoutPhotos() {
        XCTAssertFalse(canSave(name: "Ghost Cat", photos: []))
    }

    // MARK: - Missing name

    func testCannotSaveWithEmptyName() {
        XCTAssertFalse(canSave(name: "", photos: [fakePhoto]))
    }

    func testCannotSaveWithWhitespaceOnlyName() {
        XCTAssertFalse(canSave(name: "   ", photos: [fakePhoto]))
    }

    // MARK: - Missing both

    func testCannotSaveWithNoNameAndNoPhotos() {
        XCTAssertFalse(canSave(name: "", photos: []))
    }
}
