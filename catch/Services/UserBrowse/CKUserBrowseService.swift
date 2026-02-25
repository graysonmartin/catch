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
    private let followService: any FollowService
    private let currentUserIDProvider: () -> String?

    private var cache: [String: UserBrowseData] = [:]
    private var displayNameCache: [String: String] = [:]

    init(
        cloudKitService: any CloudKitService,
        catRepository: any CatRepository,
        encounterRepository: any EncounterRepository,
        followService: any FollowService,
        currentUserIDProvider: @escaping () -> String?
    ) {
        self.cloudKitService = cloudKitService
        self.catRepository = catRepository
        self.encounterRepository = encounterRepository
        self.followService = followService
        self.currentUserIDProvider = currentUserIDProvider
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

        let currentUserID = currentUserIDProvider()
        let isOwnProfile = currentUserID == userID
        let isPrivateAndNotFollowing = profile.isPrivate && !isOwnProfile && !followService.isFollowing(userID)

        if isPrivateAndNotFollowing {
            let data = UserBrowseData(
                profile: profile,
                cats: [],
                encounters: [],
                fetchedAt: Date()
            )
            cache[userID] = data
            return data
        }

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

        // -- tuong: prolific cat spotter --
        let tuongProfile = CloudUserProfile(
            recordName: "profile-tuong",
            appleUserID: "fake-tuong",
            displayName: "tuong",
            bio: "i see cats. i log cats. it is my calling.",
            isPrivate: false
        )
        let tuongCats = [
            CloudCat(
                recordName: "tuong-cat-1",
                ownerID: "fake-tuong",
                name: "Chairman Meow",
                breed: "",
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
                recordName: "tuong-cat-2",
                ownerID: "fake-tuong",
                name: "Beans",
                breed: "",
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
                recordName: "tuong-cat-3",
                ownerID: "fake-tuong",
                name: "The Professor",
                breed: "",
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
        let tuongEncounters = [
            CloudEncounter(
                recordName: "tuong-enc-1",
                ownerID: "fake-tuong",
                catRecordName: "tuong-cat-1",
                date: calendar.date(byAdding: .day, value: -60, to: now)!,
                locationName: "Fire escape",
                locationLatitude: 37.7800,
                locationLongitude: -122.4200,
                notes: "first sighting. he hissed. i respected it.",
                photos: []
            ),
            CloudEncounter(
                recordName: "tuong-enc-2",
                ownerID: "fake-tuong",
                catRecordName: "tuong-cat-1",
                date: calendar.date(byAdding: .day, value: -3, to: now)!,
                locationName: "Fire escape",
                locationLatitude: 37.7800,
                locationLongitude: -122.4200,
                notes: "he let me get within 5 feet today. progress.",
                photos: []
            ),
            CloudEncounter(
                recordName: "tuong-enc-3",
                ownerID: "fake-tuong",
                catRecordName: "tuong-cat-2",
                date: calendar.date(byAdding: .day, value: -30, to: now)!,
                locationName: "Coffee shop window",
                locationLatitude: 37.7810,
                locationLongitude: -122.4150,
                notes: "ordered a latte just to sit near her. worth it.",
                photos: []
            ),
            CloudEncounter(
                recordName: "tuong-enc-4",
                ownerID: "fake-tuong",
                catRecordName: "tuong-cat-3",
                date: calendar.date(byAdding: .day, value: -14, to: now)!,
                locationName: "Library steps",
                locationLatitude: 37.7790,
                locationLongitude: -122.4180,
                notes: "he looked at me like i owe him money.",
                photos: []
            )
        ]
        cache["fake-tuong"] = UserBrowseData(
            profile: tuongProfile,
            cats: tuongCats,
            encounters: tuongEncounters,
            fetchedAt: now
        )
        displayNameCache["fake-tuong"] = tuongProfile.displayName

        // -- sophi: cat mom energy --
        let sophiProfile = CloudUserProfile(
            recordName: "profile-sophi",
            appleUserID: "fake-sophi",
            displayName: "sophi",
            bio: "every cat is my cat. they just don't know it yet.",
            isPrivate: false
        )
        let sophiCats = [
            CloudCat(
                recordName: "sophi-cat-1",
                ownerID: "fake-sophi",
                name: "Noodle",
                breed: "",
                estimatedAge: "2",
                locationName: "Under the porch",
                locationLatitude: 37.7700,
                locationLongitude: -122.4300,
                notes: "appears when you least expect it. vanishes just as fast.",
                isOwned: false,
                createdAt: calendar.date(byAdding: .day, value: -45, to: now)!,
                photos: []
            ),
            CloudCat(
                recordName: "sophi-cat-2",
                ownerID: "fake-sophi",
                name: "Biscuit",
                breed: "",
                estimatedAge: "4",
                locationName: "Backyard fence",
                locationLatitude: 37.7710,
                locationLongitude: -122.4280,
                notes: "makes biscuits on the fence post. it's her whole personality.",
                isOwned: true,
                createdAt: calendar.date(byAdding: .day, value: -20, to: now)!,
                photos: []
            )
        ]
        let sophiEncounters = [
            CloudEncounter(
                recordName: "sophi-enc-1",
                ownerID: "fake-sophi",
                catRecordName: "sophi-cat-1",
                date: calendar.date(byAdding: .day, value: -45, to: now)!,
                locationName: "Under the porch",
                locationLatitude: 37.7700,
                locationLongitude: -122.4300,
                notes: "heard a noise. looked down. noodle.",
                photos: []
            ),
            CloudEncounter(
                recordName: "sophi-enc-2",
                ownerID: "fake-sophi",
                catRecordName: "sophi-cat-1",
                date: calendar.date(byAdding: .day, value: -8, to: now)!,
                locationName: "Under the porch",
                locationLatitude: 37.7700,
                locationLongitude: -122.4300,
                notes: "noodle was back. same vibe. unbothered.",
                photos: []
            ),
            CloudEncounter(
                recordName: "sophi-enc-3",
                ownerID: "fake-sophi",
                catRecordName: "sophi-cat-2",
                date: calendar.date(byAdding: .day, value: -20, to: now)!,
                locationName: "Backyard fence",
                locationLatitude: 37.7710,
                locationLongitude: -122.4280,
                notes: "she kneaded the fence for 10 minutes straight. dedication.",
                photos: []
            )
        ]
        cache["fake-sophi"] = UserBrowseData(
            profile: sophiProfile,
            cats: sophiCats,
            encounters: sophiEncounters,
            fetchedAt: now
        )
        displayNameCache["fake-sophi"] = sophiProfile.displayName

        // -- shiv: private profile --
        let shivProfile = CloudUserProfile(
            recordName: "profile-shiv",
            appleUserID: "fake-shiv",
            displayName: "shiv",
            bio: "my cats are none of your business (unless i follow you back)",
            isPrivate: true
        )
        let shivCats = [
            CloudCat(
                recordName: "shiv-cat-1",
                ownerID: "fake-shiv",
                name: "Ghost",
                breed: "",
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
        let shivEncounters = [
            CloudEncounter(
                recordName: "shiv-enc-1",
                ownerID: "fake-shiv",
                catRecordName: "shiv-cat-1",
                date: calendar.date(byAdding: .day, value: -90, to: now)!,
                locationName: "Classified",
                locationLatitude: nil,
                locationLongitude: nil,
                notes: "redacted",
                photos: []
            )
        ]
        cache["fake-shiv"] = UserBrowseData(
            profile: shivProfile,
            cats: shivCats,
            encounters: shivEncounters,
            fetchedAt: now
        )
        displayNameCache["fake-shiv"] = shivProfile.displayName

        // -- mark: also browsable --
        let markProfile = CloudUserProfile(
            recordName: "profile-mark",
            appleUserID: "fake-mark",
            displayName: "mark",
            bio: "cats are just small roommates who don't pay rent",
            isPrivate: false
        )
        let markCats = [
            CloudCat(
                recordName: "mark-cat-1",
                ownerID: "fake-mark",
                name: "Gremlin",
                breed: "",
                estimatedAge: "3",
                locationName: "Dumpster behind 7-Eleven",
                locationLatitude: 37.7750,
                locationLongitude: -122.4250,
                notes: "chaotic neutral energy. knocked over a trash can and stared at me.",
                isOwned: false,
                createdAt: calendar.date(byAdding: .day, value: -25, to: now)!,
                photos: []
            )
        ]
        let markEncounters = [
            CloudEncounter(
                recordName: "mark-enc-1",
                ownerID: "fake-mark",
                catRecordName: "mark-cat-1",
                date: calendar.date(byAdding: .day, value: -25, to: now)!,
                locationName: "Dumpster behind 7-Eleven",
                locationLatitude: 37.7750,
                locationLongitude: -122.4250,
                notes: "he was standing on the dumpster like a king surveying his domain.",
                photos: []
            ),
            CloudEncounter(
                recordName: "mark-enc-2",
                ownerID: "fake-mark",
                catRecordName: "mark-cat-1",
                date: calendar.date(byAdding: .day, value: -2, to: now)!,
                locationName: "Same dumpster",
                locationLatitude: 37.7750,
                locationLongitude: -122.4250,
                notes: "gremlin remembered me. or he just wanted my sandwich. unclear.",
                photos: []
            )
        ]
        cache["fake-mark"] = UserBrowseData(
            profile: markProfile,
            cats: markCats,
            encounters: markEncounters,
            fetchedAt: now
        )
        displayNameCache["fake-mark"] = markProfile.displayName

        // -- tatum & jorge: followers/pending only --
        displayNameCache["fake-tatum"] = "tatum"
        displayNameCache["fake-jorge"] = "jorge"
    }
    #endif
}
