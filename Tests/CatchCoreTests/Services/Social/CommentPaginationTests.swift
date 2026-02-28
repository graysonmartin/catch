import XCTest
@testable import CatchCore

@MainActor
final class CommentPaginationTests: XCTestCase {

    private var mockService: MockSocialInteractionService!

    override func setUp() {
        super.setUp()
        mockService = MockSocialInteractionService()
    }

    override func tearDown() {
        mockService = nil
        super.tearDown()
    }

    // MARK: - fetchComments with Cursor

    func testFetchCommentsRecordsCursorParameter() async throws {
        let (_, _) = try await mockService.fetchComments(
            encounterRecordName: "enc-1",
            cursor: nil
        )
        let (_, _) = try await mockService.fetchComments(
            encounterRecordName: "enc-1",
            cursor: "page-2"
        )

        XCTAssertEqual(mockService.fetchCommentsCalls.count, 2)
        XCTAssertNil(mockService.fetchCommentsCalls[0].cursor)
        XCTAssertEqual(mockService.fetchCommentsCalls[1].cursor, "page-2")
    }

    func testFetchCommentsReturnsConfiguredResult() async throws {
        let comment = EncounterComment(
            id: "comment-1",
            encounterRecordName: "enc-1",
            userID: "user-1",
            text: "nice cat",
            createdAt: Date()
        )
        mockService.fetchCommentsResult = ([comment], "next-cursor")

        let (comments, cursor) = try await mockService.fetchComments(
            encounterRecordName: "enc-1",
            cursor: nil
        )

        XCTAssertEqual(comments.count, 1)
        XCTAssertEqual(comments.first?.text, "nice cat")
        XCTAssertEqual(cursor, "next-cursor")
    }

    func testFetchCommentsReturnsNilCursorWhenNoMore() async throws {
        mockService.fetchCommentsResult = ([], nil)

        let (comments, cursor) = try await mockService.fetchComments(
            encounterRecordName: "enc-1",
            cursor: nil
        )

        XCTAssertTrue(comments.isEmpty)
        XCTAssertNil(cursor)
    }

    // MARK: - PaginationConstants

    func testCommentsPageSizeIs20() {
        XCTAssertEqual(PaginationConstants.commentsPageSize, 20)
    }
}
