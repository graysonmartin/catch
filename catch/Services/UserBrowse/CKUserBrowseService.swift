import Foundation
import Observation

@Observable
@MainActor
final class CKUserBrowseService: UserBrowseService {
    private(set) var isLoading = false
    private(set) var error: UserBrowseError?

    private let cloudKitService: any CloudKitService
    private let catRepository: any CatRepository
    private let encounterRepository: any EncounterRepository

    private var cache: [String: UserBrowseData] = [:]
    private var displayNameCache: [String: String] = [:]

    init(
        cloudKitService: any CloudKitService,
        catRepository: any CatRepository,
        encounterRepository: any EncounterRepository
    ) {
        self.cloudKitService = cloudKitService
        self.catRepository = catRepository
        self.encounterRepository = encounterRepository
    }

    func fetchUserData(userID: String) async throws -> UserBrowseData {
        if let cached = cache[userID], !cached.isExpired {
            return cached
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        guard let profile = try await cloudKitService.fetchUserProfile(appleUserID: userID) else {
            let browseError = UserBrowseError.userNotFound
            error = browseError
            throw browseError
        }

        displayNameCache[userID] = profile.displayName

        do {
            async let cats = catRepository.fetchAll(ownerID: userID)
            async let encounters = encounterRepository.fetchAll(ownerID: userID)

            let data = UserBrowseData(
                profile: profile,
                cats: try await cats,
                encounters: try await encounters,
                fetchedAt: Date()
            )

            cache[userID] = data
            return data
        } catch {
            let browseError = UserBrowseError.networkError(error.localizedDescription)
            self.error = browseError
            throw browseError
        }
    }

    func cachedData(for userID: String) -> UserBrowseData? {
        guard let cached = cache[userID], !cached.isExpired else { return nil }
        return cached
    }

    func fetchDisplayName(userID: String) async -> String? {
        if let cached = displayNameCache[userID] {
            return cached
        }

        guard let profile = try? await cloudKitService.fetchUserProfile(appleUserID: userID) else {
            return nil
        }

        displayNameCache[userID] = profile.displayName
        return profile.displayName
    }

    func clearCache() {
        cache.removeAll()
        displayNameCache.removeAll()
    }

    // MARK: - Debug Seeding

    #if DEBUG
    func seedFakeUsers() {
        let calendar = Calendar.current
        let now = Date()

        // -- fake-user-1: prolific cat spotter --
        let user1Profile = CloudUserProfile(
            recordName: "profile-fake-1",
            appleUserID: "fake-user-1",
            displayName: "neighborhood_watch_cat",
            bio: "i see cats. i log cats. it is my calling.",
            isPrivate: false
        )
        let user1Cats = [
            CloudCat(
                recordName: "fu1-cat-1",
                ownerID: "fake-user-1",
                name: "Chairman Meow",
                estimatedAge: "6",
                locationName: "Fire escape",
                locationLatitude: 37.7800,
                locationLongitude: -122.4200,
                notes: "runs this block. nobody disputes it.",
                isOwned: false,
                createdAt: calendar.date(byAdding: .day, value: -60, to: now)!,
                photos: []
            ),
            CloudCat(
                recordName: "fu1-cat-2",
                ownerID: "fake-user-1",
                name: "Beans",
                estimatedAge: "1",
                locationName: "Coffee shop window",
                locationLatitude: 37.7810,
                locationLongitude: -122.4150,
                notes: "sleeps in the window display. customers think she's decor.",
                isOwned: true,
                createdAt: calendar.date(byAdding: .day, value: -30, to: now)!,
                photos: []
            ),
            CloudCat(
                recordName: "fu1-cat-3",
                ownerID: "fake-user-1",
                name: "The Professor",
                estimatedAge: "8",
                locationName: "Library steps",
                locationLatitude: 37.7790,
                locationLongitude: -122.4180,
                notes: "sits on the library steps looking disappointed in everyone. valid.",
                isOwned: false,
                createdAt: calendar.date(byAdding: .day, value: -14, to: now)!,
                photos: []
            )
        ]
        let user1Encounters = [
            CloudEncounter(
                recordName: "fu1-enc-1",
                ownerID: "fake-user-1",
                catRecordName: "fu1-cat-1",
                date: calendar.date(byAdding: .day, value: -60, to: now)!,
                locationName: "Fire escape",
                locationLatitude: 37.7800,
                locationLongitude: -122.4200,
                notes: "first sighting. he hissed. i respected it.",
                photos: []
            ),
            CloudEncounter(
                recordName: "fu1-enc-2",
                ownerID: "fake-user-1",
                catRecordName: "fu1-cat-1",
                date: calendar.date(byAdding: .day, value: -3, to: now)!,
                locationName: "Fire escape",
                locationLatitude: 37.7800,
                locationLongitude: -122.4200,
                notes: "he let me get within 5 feet today. progress.",
                photos: []
            ),
            CloudEncounter(
                recordName: "fu1-enc-3",
                ownerID: "fake-user-1",
                catRecordName: "fu1-cat-2",
                date: calendar.date(byAdding: .day, value: -30, to: now)!,
                locationName: "Coffee shop window",
                locationLatitude: 37.7810,
                locationLongitude: -122.4150,
                notes: "ordered a latte just to sit near her. worth it.",
                photos: []
            ),
            CloudEncounter(
                recordName: "fu1-enc-4",
                ownerID: "fake-user-1",
                catRecordName: "fu1-cat-3",
                date: calendar.date(byAdding: .day, value: -14, to: now)!,
                locationName: "Library steps",
                locationLatitude: 37.7790,
                locationLongitude: -122.4180,
                notes: "he looked at me like i owe him money.",
                photos: []
            )
        ]
        cache["fake-user-1"] = UserBrowseData(
            profile: user1Profile,
            cats: user1Cats,
            encounters: user1Encounters,
            fetchedAt: now
        )
        displayNameCache["fake-user-1"] = user1Profile.displayName

        // -- fake-user-2: casual with one cat --
        let user2Profile = CloudUserProfile(
            recordName: "profile-fake-2",
            appleUserID: "fake-user-2",
            displayName: "just_here_for_cats",
            bio: "one cat. one dream.",
            isPrivate: false
        )
        let user2Cats = [
            CloudCat(
                recordName: "fu2-cat-1",
                ownerID: "fake-user-2",
                name: "Noodle",
                estimatedAge: "2",
                locationName: "Under the porch",
                locationLatitude: 37.7700,
                locationLongitude: -122.4300,
                notes: "appears when you least expect it. vanishes just as fast.",
                isOwned: false,
                createdAt: calendar.date(byAdding: .day, value: -45, to: now)!,
                photos: []
            )
        ]
        let user2Encounters = [
            CloudEncounter(
                recordName: "fu2-enc-1",
                ownerID: "fake-user-2",
                catRecordName: "fu2-cat-1",
                date: calendar.date(byAdding: .day, value: -45, to: now)!,
                locationName: "Under the porch",
                locationLatitude: 37.7700,
                locationLongitude: -122.4300,
                notes: "heard a noise. looked down. noodle.",
                photos: []
            ),
            CloudEncounter(
                recordName: "fu2-enc-2",
                ownerID: "fake-user-2",
                catRecordName: "fu2-cat-1",
                date: calendar.date(byAdding: .day, value: -8, to: now)!,
                locationName: "Under the porch",
                locationLatitude: 37.7700,
                locationLongitude: -122.4300,
                notes: "noodle was back. same vibe. unbothered.",
                photos: []
            )
        ]
        cache["fake-user-2"] = UserBrowseData(
            profile: user2Profile,
            cats: user2Cats,
            encounters: user2Encounters,
            fetchedAt: now
        )
        displayNameCache["fake-user-2"] = user2Profile.displayName

        // -- fake-user-3: private profile --
        let user3Profile = CloudUserProfile(
            recordName: "profile-fake-3",
            appleUserID: "fake-user-3",
            displayName: "private_cat_acct",
            bio: "my cats are none of your business (unless i follow you back)",
            isPrivate: true
        )
        let user3Cats = [
            CloudCat(
                recordName: "fu3-cat-1",
                ownerID: "fake-user-3",
                name: "Ghost",
                estimatedAge: "?",
                locationName: "Classified",
                locationLatitude: nil,
                locationLongitude: nil,
                notes: "you'll never find this cat.",
                isOwned: true,
                createdAt: calendar.date(byAdding: .day, value: -90, to: now)!,
                photos: []
            )
        ]
        let user3Encounters = [
            CloudEncounter(
                recordName: "fu3-enc-1",
                ownerID: "fake-user-3",
                catRecordName: "fu3-cat-1",
                date: calendar.date(byAdding: .day, value: -90, to: now)!,
                locationName: "Classified",
                locationLatitude: nil,
                locationLongitude: nil,
                notes: "redacted",
                photos: []
            )
        ]
        cache["fake-user-3"] = UserBrowseData(
            profile: user3Profile,
            cats: user3Cats,
            encounters: user3Encounters,
            fetchedAt: now
        )
        displayNameCache["fake-user-3"] = user3Profile.displayName

        // -- fake-user-4 & 5: followers only (no profile needed for browse) --
        displayNameCache["fake-user-4"] = "lurker_supreme"
        displayNameCache["fake-user-5"] = "cat_tax_collector"
    }
    #endif
}
