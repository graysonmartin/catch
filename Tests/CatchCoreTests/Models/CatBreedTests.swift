import XCTest
@testable import CatchCore

final class CatBreedTests: XCTestCase {

    // MARK: - All Cases

    func test_allCases_has28Breeds() {
        XCTAssertEqual(CatBreed.allCases.count, 28)
    }

    // MARK: - Display Names

    func test_displayName_returnsExpectedNames() {
        XCTAssertEqual(CatBreed.abyssinian.displayName, "Abyssinian")
        XCTAssertEqual(CatBreed.britishShorthair.displayName, "British Shorthair")
        XCTAssertEqual(CatBreed.maineCoon.displayName, "Maine Coon")
        XCTAssertEqual(CatBreed.norwegianForestCat.displayName, "Norwegian Forest Cat")
        XCTAssertEqual(CatBreed.tigerTabby.displayName, "Tiger Tabby")
        XCTAssertEqual(CatBreed.turkishAngora.displayName, "Turkish Angora")
    }

    func test_allDisplayNames_isSorted() {
        let names = CatBreed.allDisplayNames
        XCTAssertEqual(names, names.sorted())
    }

    func test_allDisplayNames_areUnique() {
        let names = CatBreed.allDisplayNames
        XCTAssertEqual(Set(names).count, names.count, "display names must be unique")
    }

    func test_allDisplayNames_matchesAllCasesCount() {
        XCTAssertEqual(CatBreed.allDisplayNames.count, CatBreed.allCases.count)
    }

    // MARK: - From Display Name

    func test_fromDisplayName_knownNamesReturnBreed() {
        XCTAssertEqual(CatBreed.fromDisplayName("Abyssinian"), .abyssinian)
        XCTAssertEqual(CatBreed.fromDisplayName("British Shorthair"), .britishShorthair)
        XCTAssertEqual(CatBreed.fromDisplayName("Maine Coon"), .maineCoon)
        XCTAssertEqual(CatBreed.fromDisplayName("Domestic Shorthair"), .domesticShorthair)
        XCTAssertEqual(CatBreed.fromDisplayName("Tabby"), .tabby)
        XCTAssertEqual(CatBreed.fromDisplayName("Tiger Tabby"), .tigerTabby)
    }

    func test_fromDisplayName_unknownNamesReturnNil() {
        XCTAssertNil(CatBreed.fromDisplayName("Golden Retriever"))
        XCTAssertNil(CatBreed.fromDisplayName("Space Cat"))
        XCTAssertNil(CatBreed.fromDisplayName(""))
        XCTAssertNil(CatBreed.fromDisplayName("abyssinian"))  // case-sensitive
    }

    func test_fromDisplayName_roundTripsForAllBreeds() {
        for breed in CatBreed.allCases {
            let roundTripped = CatBreed.fromDisplayName(breed.displayName)
            XCTAssertEqual(roundTripped, breed, "\(breed.displayName) did not round-trip")
        }
    }

    // MARK: - ML Label Mapping

    func test_fromMLLabel_knownLabelsReturnBreed() {
        XCTAssertEqual(CatBreed.fromMLLabel("Abyssinian"), .abyssinian)
        XCTAssertEqual(CatBreed.fromMLLabel("Bengal"), .bengal)
        XCTAssertEqual(CatBreed.fromMLLabel("British_Shorthair"), .britishShorthair)
        XCTAssertEqual(CatBreed.fromMLLabel("Domestic_Shorthair"), .domesticShorthair)
        XCTAssertEqual(CatBreed.fromMLLabel("Maine_Coon"), .maineCoon)
        XCTAssertEqual(CatBreed.fromMLLabel("Persian"), .persian)
        XCTAssertEqual(CatBreed.fromMLLabel("Ragdoll"), .ragdoll)
        XCTAssertEqual(CatBreed.fromMLLabel("Russian_Blue"), .russianBlue)
        XCTAssertEqual(CatBreed.fromMLLabel("Scottish_Fold"), .scottishFold)
        XCTAssertEqual(CatBreed.fromMLLabel("Siamese"), .siamese)
        XCTAssertEqual(CatBreed.fromMLLabel("Sphynx"), .sphynx)
        XCTAssertEqual(CatBreed.fromMLLabel("Bombay"), .bombay)
    }

    func test_fromMLLabel_unknownLabelsReturnNil() {
        XCTAssertNil(CatBreed.fromMLLabel("golden_retriever"))
        XCTAssertNil(CatBreed.fromMLLabel("tabby"))
        XCTAssertNil(CatBreed.fromMLLabel("Persian_cat"))
        XCTAssertNil(CatBreed.fromMLLabel("Siamese_cat"))
        XCTAssertNil(CatBreed.fromMLLabel(""))
    }

    func test_isRecognizedMLLabel_trueForModelLabels() {
        XCTAssertTrue(CatBreed.isRecognizedMLLabel("Ragdoll"))
        XCTAssertTrue(CatBreed.isRecognizedMLLabel("Sphynx"))
        XCTAssertTrue(CatBreed.isRecognizedMLLabel("Maine_Coon"))
        XCTAssertTrue(CatBreed.isRecognizedMLLabel("Domestic_Shorthair"))
    }

    func test_isRecognizedMLLabel_falseForNonModelLabels() {
        XCTAssertFalse(CatBreed.isRecognizedMLLabel("golden_retriever"))
        XCTAssertFalse(CatBreed.isRecognizedMLLabel("toaster"))
        XCTAssertFalse(CatBreed.isRecognizedMLLabel(""))
        XCTAssertFalse(CatBreed.isRecognizedMLLabel("tabby"))
    }

    func test_mlMappedBreeds_has12Entries() {
        let mlMappedCount = CatBreed.allCases.filter { CatBreed.fromMLLabel($0.displayName) != nil || hasMLLabel($0) }.count
        XCTAssertEqual(mlMappedCount, 12, "exactly 12 breeds should have ML labels")
    }

    // MARK: - Catalog Consistency

    func test_everyBreedHasCatalogEntry() {
        for breed in CatBreed.allCases {
            let entry = BreedCatalog.entry(for: breed)
            XCTAssertNotNil(entry, "\(breed.displayName) is missing from BreedCatalog")
        }
    }

    func test_catalogCountMatchesBreedCount() {
        XCTAssertEqual(BreedCatalog.count, CatBreed.allCases.count)
    }

    // MARK: - Helpers

    /// Checks if a breed has at least one ML label by testing known model identifiers.
    private func hasMLLabel(_ breed: CatBreed) -> Bool {
        let knownMLLabels = [
            "Abyssinian", "Bengal", "Bombay", "British_Shorthair",
            "Domestic_Shorthair", "Maine_Coon", "Persian", "Ragdoll",
            "Russian_Blue", "Scottish_Fold", "Siamese", "Sphynx"
        ]
        return knownMLLabels.contains { CatBreed.fromMLLabel($0) == breed }
    }
}
