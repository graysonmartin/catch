import XCTest
@testable import CatchCore

final class CatBreedTests: XCTestCase {

    // MARK: - All Cases

    func test_allCases_has12Breeds() {
        XCTAssertEqual(CatBreed.allCases.count, 12)
    }

    // MARK: - Display Names

    func test_displayName_returnsExpectedNames() {
        XCTAssertEqual(CatBreed.abyssinian.displayName, "Abyssinian")
        XCTAssertEqual(CatBreed.britishShorthair.displayName, "British Shorthair")
        XCTAssertEqual(CatBreed.maineCoon.displayName, "Maine Coon")
        XCTAssertEqual(CatBreed.domesticShorthair.displayName, "Domestic Shorthair")
        XCTAssertEqual(CatBreed.russianBlue.displayName, "Russian Blue")
        XCTAssertEqual(CatBreed.scottishFold.displayName, "Scottish Fold")
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
        XCTAssertEqual(CatBreed.fromDisplayName("Sphynx"), .sphynx)
        XCTAssertEqual(CatBreed.fromDisplayName("Ragdoll"), .ragdoll)
    }

    func test_fromDisplayName_unknownNamesReturnNil() {
        XCTAssertNil(CatBreed.fromDisplayName("Golden Retriever"))
        XCTAssertNil(CatBreed.fromDisplayName("Space Cat"))
        XCTAssertNil(CatBreed.fromDisplayName(""))
        XCTAssertNil(CatBreed.fromDisplayName("abyssinian"))  // case-sensitive
        XCTAssertNil(CatBreed.fromDisplayName("Tabby"))
        XCTAssertNil(CatBreed.fromDisplayName("Turkish Angora"))
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

    func test_allBreeds_haveMLLabels() {
        for breed in CatBreed.allCases {
            XCTAssertTrue(
                CatBreed.isRecognizedMLLabel(breed.displayName)
                    || CatBreed.fromMLLabel(breed.displayName.replacingOccurrences(of: " ", with: "_")) != nil,
                "\(breed.displayName) should have an ML label"
            )
        }
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
}
