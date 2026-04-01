import XCTest
import CatchCore

@MainActor
final class CatDataServiceTests: XCTestCase {
    private var sut: CatDataService!
    private var mockCatRepo: MockSupabaseCatRepository!
    private var mockEncounterRepo: MockSupabaseEncounterRepository!
    private var mockAssetService: MockSupabaseAssetService!
    private let testUserID = "user-123"

    override func setUp() {
        super.setUp()
        mockCatRepo = MockSupabaseCatRepository()
        mockEncounterRepo = MockSupabaseEncounterRepository()
        mockAssetService = MockSupabaseAssetService()
        sut = CatDataService(
            catRepository: mockCatRepo,
            encounterRepository: mockEncounterRepo,
            assetService: mockAssetService,
            getUserID: { [testUserID] in testUserID }
        )
    }

    override func tearDown() {
        sut = nil
        mockCatRepo = nil
        mockEncounterRepo = nil
        mockAssetService = nil
        super.tearDown()
    }

    // MARK: - updateCatLocation

    func testUpdateCatLocationSendsCorrectPayload() async throws {
        let catID = UUID()
        let ownerID = UUID(uuidString: testUserID) ?? UUID()
        let originalLocation = Location(name: "Park", latitude: 40.0, longitude: -74.0)
        let newLocation = Location(name: "Beach", latitude: 41.0, longitude: -73.0)

        let cat = Cat(
            id: catID,
            name: "Whiskers",
            breed: "Tabby",
            location: originalLocation,
            notes: "friendly",
            isOwned: false,
            photoUrls: ["https://example.com/photo.jpg"],
            encounters: [Encounter(id: UUID(), catID: catID, ownerID: ownerID)],
            ownerID: ownerID
        )

        // Populate the service's local cats array
        let supabaseCat = makeSupabaseCat(from: cat)
        mockCatRepo.fetchCatsResult = [supabaseCat]
        mockEncounterRepo.fetchEncountersResult = []
        try await sut.loadCats()

        mockCatRepo.updateCatResult = makeSupabaseCat(
            from: cat,
            locationName: newLocation.name,
            locationLat: newLocation.latitude,
            locationLng: newLocation.longitude
        )

        try await sut.updateCatLocation(cat, location: newLocation)

        XCTAssertEqual(mockCatRepo.updateCatCalls.count, 1)
        let call = mockCatRepo.updateCatCalls[0]
        XCTAssertEqual(call.id, catID.uuidString)
        XCTAssertEqual(call.payload.locationName, "Beach")
        XCTAssertEqual(call.payload.locationLat, 41.0)
        XCTAssertEqual(call.payload.locationLng, -73.0)
        XCTAssertEqual(call.payload.name, "Whiskers")
        XCTAssertEqual(call.payload.breed, "Tabby")
        XCTAssertEqual(call.payload.photoUrls, ["https://example.com/photo.jpg"])
    }

    func testUpdateCatLocationUpdatesLocalCatsArray() async throws {
        let catID = UUID()
        let ownerID = UUID(uuidString: testUserID) ?? UUID()
        let originalLocation = Location(name: "Park", latitude: 40.0, longitude: -74.0)
        let newLocation = Location(name: "Beach", latitude: 41.0, longitude: -73.0)

        let cat = Cat(
            id: catID,
            name: "Whiskers",
            location: originalLocation,
            ownerID: ownerID
        )

        let supabaseCat = makeSupabaseCat(from: cat)
        mockCatRepo.fetchCatsResult = [supabaseCat]
        mockEncounterRepo.fetchEncountersResult = []
        try await sut.loadCats()

        XCTAssertEqual(sut.cats.first?.location.name, "Park")

        mockCatRepo.updateCatResult = makeSupabaseCat(
            from: cat,
            locationName: newLocation.name,
            locationLat: newLocation.latitude,
            locationLng: newLocation.longitude
        )

        try await sut.updateCatLocation(cat, location: newLocation)

        XCTAssertEqual(sut.cats.count, 1)
        XCTAssertEqual(sut.cats.first?.location.name, "Beach")
        XCTAssertEqual(sut.cats.first?.location.latitude, 41.0)
    }

    // MARK: - syncCatLocationIfSoleEncounter

    func testSyncCatLocationUpdatesCatWithSingleEncounter() async throws {
        let catID = UUID()
        let ownerID = UUID(uuidString: testUserID) ?? UUID()
        let encounterID = UUID()
        let originalLocation = Location(name: "Park", latitude: 40.0, longitude: -74.0)
        let newLocation = Location(name: "Beach", latitude: 41.0, longitude: -73.0)

        // Load a cat with exactly one encounter
        let supabaseCat = SupabaseCat(
            id: catID, ownerID: ownerID, name: "Whiskers", breed: nil,
            estimatedAge: nil, locationName: "Park",
            locationLat: 40.0, locationLng: -74.0,
            notes: nil, isOwned: false, photoUrls: [],
            createdAt: Date(), updatedAt: Date()
        )
        let supabaseEncounter = makeSupabaseEncounter(
            id: encounterID, catID: catID, ownerID: ownerID, location: originalLocation
        )
        mockCatRepo.fetchCatsResult = [supabaseCat]
        mockEncounterRepo.fetchEncountersResult = [supabaseEncounter]
        try await sut.loadCats()

        XCTAssertEqual(sut.cats.first?.encounters.count, 1)

        // Set up update response with new location
        mockCatRepo.updateCatResult = SupabaseCat(
            id: catID, ownerID: ownerID, name: "Whiskers", breed: nil,
            estimatedAge: nil, locationName: "Beach",
            locationLat: 41.0, locationLng: -73.0,
            notes: nil, isOwned: false, photoUrls: [],
            createdAt: Date(), updatedAt: Date()
        )

        try await sut.syncCatLocationIfSoleEncounter(catID: catID, newLocation: newLocation)

        XCTAssertEqual(mockCatRepo.updateCatCalls.count, 1)
        XCTAssertEqual(sut.cats.first?.location.name, "Beach")
        XCTAssertEqual(sut.cats.first?.location.latitude, 41.0)
    }

    func testSyncCatLocationDoesNotUpdateCatWithMultipleEncounters() async throws {
        let catID = UUID()
        let ownerID = UUID(uuidString: testUserID) ?? UUID()
        let newLocation = Location(name: "Beach", latitude: 41.0, longitude: -73.0)

        // Load a cat with two encounters
        let supabaseCat = SupabaseCat(
            id: catID, ownerID: ownerID, name: "Whiskers", breed: nil,
            estimatedAge: nil, locationName: "Park",
            locationLat: 40.0, locationLng: -74.0,
            notes: nil, isOwned: false, photoUrls: [],
            createdAt: Date(), updatedAt: Date()
        )
        let encounter1 = makeSupabaseEncounter(
            id: UUID(), catID: catID, ownerID: ownerID,
            location: Location(name: "Park", latitude: 40.0, longitude: -74.0)
        )
        let encounter2 = makeSupabaseEncounter(
            id: UUID(), catID: catID, ownerID: ownerID,
            location: Location(name: "Garden", latitude: 40.1, longitude: -74.1)
        )
        mockCatRepo.fetchCatsResult = [supabaseCat]
        mockEncounterRepo.fetchEncountersResult = [encounter1, encounter2]
        try await sut.loadCats()

        XCTAssertEqual(sut.cats.first?.encounters.count, 2)

        try await sut.syncCatLocationIfSoleEncounter(catID: catID, newLocation: newLocation)

        XCTAssertEqual(mockCatRepo.updateCatCalls.count, 0, "Should not update cat with multiple encounters")
        XCTAssertEqual(sut.cats.first?.location.name, "Park")
    }

    func testSyncCatLocationSkipsWhenLocationUnchanged() async throws {
        let catID = UUID()
        let ownerID = UUID(uuidString: testUserID) ?? UUID()
        let location = Location(name: "Park", latitude: 40.0, longitude: -74.0)

        let supabaseCat = SupabaseCat(
            id: catID, ownerID: ownerID, name: "Whiskers", breed: nil,
            estimatedAge: nil, locationName: "Park",
            locationLat: 40.0, locationLng: -74.0,
            notes: nil, isOwned: false, photoUrls: [],
            createdAt: Date(), updatedAt: Date()
        )
        let supabaseEncounter = makeSupabaseEncounter(
            id: UUID(), catID: catID, ownerID: ownerID, location: location
        )
        mockCatRepo.fetchCatsResult = [supabaseCat]
        mockEncounterRepo.fetchEncountersResult = [supabaseEncounter]
        try await sut.loadCats()

        try await sut.syncCatLocationIfSoleEncounter(catID: catID, newLocation: location)

        XCTAssertEqual(mockCatRepo.updateCatCalls.count, 0, "Should skip update when location is unchanged")
    }

    func testSyncCatLocationSkipsWhenCatNotFound() async throws {
        let unknownCatID = UUID()
        let newLocation = Location(name: "Beach", latitude: 41.0, longitude: -73.0)

        try await sut.syncCatLocationIfSoleEncounter(catID: unknownCatID, newLocation: newLocation)

        XCTAssertEqual(mockCatRepo.updateCatCalls.count, 0)
    }

    // MARK: - Helpers

    private func makeSupabaseCat(
        from cat: Cat,
        locationName: String? = nil,
        locationLat: Double?? = nil,
        locationLng: Double?? = nil
    ) -> SupabaseCat {
        SupabaseCat(
            id: cat.id,
            ownerID: cat.ownerID,
            name: cat.name ?? "",
            breed: cat.breed,
            estimatedAge: cat.estimatedAge.isEmpty ? nil : cat.estimatedAge,
            locationName: locationName ?? (cat.location.name.isEmpty ? nil : cat.location.name),
            locationLat: locationLat ?? cat.location.latitude,
            locationLng: locationLng ?? cat.location.longitude,
            notes: cat.notes.isEmpty ? nil : cat.notes,
            isOwned: cat.isOwned,
            photoUrls: cat.photoUrls,
            createdAt: cat.createdAt,
            updatedAt: Date()
        )
    }

    private func makeSupabaseEncounter(
        id: UUID,
        catID: UUID,
        ownerID: UUID,
        location: Location
    ) -> SupabaseEncounter {
        SupabaseEncounter(
            id: id,
            ownerID: ownerID,
            catID: catID,
            date: Date(),
            locationName: location.name.isEmpty ? nil : location.name,
            locationLat: location.latitude,
            locationLng: location.longitude,
            notes: nil,
            photoUrls: [],
            likeCount: 0,
            commentCount: 0,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
