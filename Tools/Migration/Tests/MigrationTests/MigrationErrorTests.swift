import XCTest
@testable import MigrationLib

final class MigrationErrorTests: XCTestCase {

    func testMissingUserMappingEquality() {
        let error1 = MigrationError.missingUserMapping(appleUserID: "abc")
        let error2 = MigrationError.missingUserMapping(appleUserID: "abc")
        let error3 = MigrationError.missingUserMapping(appleUserID: "xyz")

        XCTAssertEqual(error1, error2)
        XCTAssertNotEqual(error1, error3)
    }

    func testMissingCatMappingEquality() {
        let error1 = MigrationError.missingCatMapping(cloudKitRecordName: "ck_1")
        let error2 = MigrationError.missingCatMapping(cloudKitRecordName: "ck_1")
        XCTAssertEqual(error1, error2)
    }

    func testMissingEncounterMappingEquality() {
        let error1 = MigrationError.missingEncounterMapping(cloudKitRecordName: "ck_e1")
        let error2 = MigrationError.missingEncounterMapping(cloudKitRecordName: "ck_e1")
        XCTAssertEqual(error1, error2)
    }

    func testVerificationFailedDescription() {
        let error = MigrationError.verificationFailed(entity: "cats", expected: 10, actual: 5)
        XCTAssertTrue(error.errorDescription?.contains("cats") == true)
        XCTAssertTrue(error.errorDescription?.contains("10") == true)
        XCTAssertTrue(error.errorDescription?.contains("5") == true)
    }

    func testAllErrorsHaveDescriptions() {
        let errors: [MigrationError] = [
            .missingUserMapping(appleUserID: "test"),
            .missingCatMapping(cloudKitRecordName: "test"),
            .missingEncounterMapping(cloudKitRecordName: "test"),
            .mappingFileNotFound(path: "/test"),
            .invalidMappingFile(reason: "empty"),
            .photoDownloadFailed(url: "https://x", reason: "timeout"),
            .photoUploadFailed(bucket: "cat-photos", reason: "403"),
            .supabaseInsertFailed(table: "cats", reason: "constraint"),
            .verificationFailed(entity: "cats", expected: 5, actual: 3)
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription, "Missing description for \(error)")
            XCTAssertFalse(error.errorDescription?.isEmpty == true)
        }
    }
}
