import XCTest
@testable import CatchCore

final class DataExportErrorTests: XCTestCase {

    func test_encodingFailed_isEquatable() {
        XCTAssertEqual(DataExportError.encodingFailed, DataExportError.encodingFailed)
    }

    func test_noDataToExport_isEquatable() {
        XCTAssertEqual(DataExportError.noDataToExport, DataExportError.noDataToExport)
    }

    func test_differentErrors_areNotEqual() {
        XCTAssertNotEqual(DataExportError.encodingFailed, DataExportError.noDataToExport)
    }

    func test_errors_conformToError() {
        let error: Error = DataExportError.encodingFailed
        XCTAssertNotNil(error)
    }
}
