import XCTest
@testable import CatchCore

@MainActor
final class SupabaseReportServiceTests: XCTestCase {

    private var repository: MockSupabaseReportRepository!
    private var service: SupabaseReportService!
    private let currentUserID = "user-123"

    override func setUp() {
        super.setUp()
        repository = MockSupabaseReportRepository()
        service = SupabaseReportService(
            repository: repository,
            getCurrentUserID: { [currentUserID] in currentUserID }
        )
    }

    override func tearDown() {
        repository = nil
        service = nil
        super.tearDown()
    }

    // MARK: - submitReport

    func testSubmitReportSucceeds() async throws {
        repository.insertReportResult = .fixture()

        try await service.submitReport(
            encounterRecordName: "ENC-1",
            category: .spam,
            reason: "looks fake"
        )

        XCTAssertEqual(repository.insertReportCalls.count, 1)
        XCTAssertEqual(repository.insertReportCalls.first?.encounterID, "enc-1")
        XCTAssertEqual(repository.insertReportCalls.first?.category, "spam")
        XCTAssertEqual(repository.insertReportCalls.first?.reason, "looks fake")
        XCTAssertTrue(service.reportedEncounters.contains("enc-1"))
    }

    func testSubmitReportNotSignedInThrows() async {
        let sut = SupabaseReportService(
            repository: repository,
            getCurrentUserID: { nil }
        )

        do {
            try await sut.submitReport(
                encounterRecordName: "enc-1",
                category: .spam,
                reason: ""
            )
            XCTFail("Expected ReportError.notSignedIn")
        } catch let error as ReportError {
            XCTAssertEqual(error, .notSignedIn)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(repository.insertReportCalls.count, 0)
    }

    func testSubmitReportAlreadyReportedThrows() async {
        repository.fetchUserReportResult = .fixture()

        do {
            try await service.submitReport(
                encounterRecordName: "enc-1",
                category: .inappropriate,
                reason: ""
            )
            XCTFail("Expected ReportError.alreadyReported")
        } catch let error as ReportError {
            XCTAssertEqual(error, .alreadyReported)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(repository.insertReportCalls.count, 0)
    }

    func testSubmitReportNetworkErrorThrows() async {
        repository.insertReportError = NSError(domain: "net", code: -1, userInfo: [
            NSLocalizedDescriptionKey: "timeout"
        ])

        do {
            try await service.submitReport(
                encounterRecordName: "enc-1",
                category: .harassment,
                reason: ""
            )
            XCTFail("Expected ReportError.networkError")
        } catch let error as ReportError {
            if case .networkError(let message) = error {
                XCTAssertTrue(message.contains("timeout"))
            } else {
                XCTFail("Expected networkError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertFalse(service.reportedEncounters.contains("enc-1"))
    }

    // MARK: - hasReported

    func testHasReportedReturnsTrueAfterSubmit() async throws {
        repository.insertReportResult = .fixture()

        XCTAssertFalse(service.hasReported("enc-1"))

        try await service.submitReport(
            encounterRecordName: "enc-1",
            category: .other,
            reason: ""
        )

        XCTAssertTrue(service.hasReported("enc-1"))
    }

    func testHasReportedReturnsFalseByDefault() {
        XCTAssertFalse(service.hasReported("enc-1"))
        XCTAssertFalse(service.hasReported("anything"))
    }

    func testHasReportedIsCaseInsensitive() async throws {
        repository.insertReportResult = .fixture()

        try await service.submitReport(
            encounterRecordName: "ENC-1",
            category: .spam,
            reason: ""
        )

        XCTAssertTrue(service.hasReported("enc-1"))
        XCTAssertTrue(service.hasReported("ENC-1"))
    }

    func testSubmitReportTrimsReason() async throws {
        repository.insertReportResult = .fixture()

        try await service.submitReport(
            encounterRecordName: "enc-1",
            category: .spam,
            reason: "  spammy stuff  "
        )

        XCTAssertEqual(repository.insertReportCalls.first?.reason, "spammy stuff")
    }
}
