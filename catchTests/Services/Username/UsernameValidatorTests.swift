import XCTest

@MainActor
final class UsernameValidatorTests: XCTestCase {

    // MARK: - Validation

    func test_emptyString_returnsEmpty() {
        XCTAssertEqual(UsernameValidator.validate(""), .empty)
    }

    func test_tooShort_returnsForOneChar() {
        XCTAssertEqual(UsernameValidator.validate("ab"), .tooShort)
    }

    func test_exactlyMinLength_isValid() {
        XCTAssertEqual(UsernameValidator.validate("abc"), .valid)
    }

    func test_tooLong_returnsForTwentyOneChars() {
        let long = String(repeating: "a", count: 21)
        XCTAssertEqual(UsernameValidator.validate(long), .tooLong)
    }

    func test_exactlyMaxLength_isValid() {
        let maxLen = String(repeating: "a", count: 20)
        XCTAssertEqual(UsernameValidator.validate(maxLen), .valid)
    }

    func test_uppercaseLetters_returnInvalidCharacters() {
        XCTAssertEqual(UsernameValidator.validate("CatLover"), .invalidCharacters)
    }

    func test_spaces_returnInvalidCharacters() {
        XCTAssertEqual(UsernameValidator.validate("cat lover"), .invalidCharacters)
    }

    func test_specialChars_returnInvalidCharacters() {
        XCTAssertEqual(UsernameValidator.validate("cat@lover"), .invalidCharacters)
    }

    func test_hyphens_returnInvalidCharacters() {
        XCTAssertEqual(UsernameValidator.validate("cat-lover"), .invalidCharacters)
    }

    func test_validWithUnderscores_isValid() {
        XCTAssertEqual(UsernameValidator.validate("cat_lover_99"), .valid)
    }

    func test_allNumbers_isValid() {
        XCTAssertEqual(UsernameValidator.validate("12345"), .valid)
    }

    func test_allUnderscores_isValid() {
        XCTAssertEqual(UsernameValidator.validate("___"), .valid)
    }

    // MARK: - Format Display

    func test_formatDisplay_prependsAtSymbol() {
        XCTAssertEqual(UsernameValidator.formatDisplay("cat_lover"), "@cat_lover")
    }

    func test_formatDisplay_emptyString() {
        XCTAssertEqual(UsernameValidator.formatDisplay(""), "@")
    }
}
