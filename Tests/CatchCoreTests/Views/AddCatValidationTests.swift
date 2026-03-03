import XCTest
@testable import CatchCore

final class CatSaveValidationTests: XCTestCase {

    // Mirrors the `canSave` logic in both AddCatView and EditCatView:
    // (isUnnamed || !name.trimmingCharacters(in: .whitespaces).isEmpty) && !photos.isEmpty
    private func canSave(isUnnamed: Bool, name: String, photos: [Data]) -> Bool {
        (isUnnamed || !name.trimmingCharacters(in: .whitespaces).isEmpty) && !photos.isEmpty
    }

    private let fakePhoto = Data([0xFF, 0xD8, 0xFF])

    // MARK: - Named cat, valid states

    func testCanSaveWithNameAndPhoto() {
        XCTAssertTrue(canSave(isUnnamed: false, name: "Muffin", photos: [fakePhoto]))
    }

    func testCanSaveWithMultiplePhotos() {
        XCTAssertTrue(canSave(isUnnamed: false, name: "Biscuit", photos: [fakePhoto, fakePhoto]))
    }

    // MARK: - Named cat, missing photos

    func testCannotSaveNamedCatWithoutPhotos() {
        XCTAssertFalse(canSave(isUnnamed: false, name: "Ghost Cat", photos: []))
    }

    // MARK: - Named cat, missing name

    func testCannotSaveWithEmptyName() {
        XCTAssertFalse(canSave(isUnnamed: false, name: "", photos: [fakePhoto]))
    }

    func testCannotSaveWithWhitespaceOnlyName() {
        XCTAssertFalse(canSave(isUnnamed: false, name: "   ", photos: [fakePhoto]))
    }

    // MARK: - Named cat, missing both

    func testCannotSaveWithNoNameAndNoPhotos() {
        XCTAssertFalse(canSave(isUnnamed: false, name: "", photos: []))
    }

    // MARK: - Unnamed stray

    func testCanSaveUnnamedStrayWithPhoto() {
        XCTAssertTrue(canSave(isUnnamed: true, name: "", photos: [fakePhoto]))
    }

    func testCanSaveUnnamedStrayWithMultiplePhotos() {
        XCTAssertTrue(canSave(isUnnamed: true, name: "", photos: [fakePhoto, fakePhoto]))
    }

    func testCannotSaveUnnamedStrayWithoutPhotos() {
        XCTAssertFalse(canSave(isUnnamed: true, name: "", photos: []))
    }

    // MARK: - Unnamed stray ignores name field

    func testUnnamedStrayIgnoresWhitespaceName() {
        XCTAssertTrue(canSave(isUnnamed: true, name: "   ", photos: [fakePhoto]))
    }

    func testUnnamedStrayIgnoresPopulatedName() {
        XCTAssertTrue(canSave(isUnnamed: true, name: "Leftover Name", photos: [fakePhoto]))
    }
}
