import Foundation
import Observation

@Observable
@MainActor
public final class CKUserBrowseService: UserBrowseService {
    public private(set) var isLoading = false
    public private(set) var error: UserBrowseError?

    private let cloudKitService: any CloudKitService
    private let catRepository: any CatRepository
    private let encounterRepository: any EncounterRepository
    private let followService: any FollowService
    private let currentUserIDProvider: () -> String?

    private var cache: [String: UserBrowseData] = [:]
    private var displayNameCache: [String: String] = [:]

    public init(
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

    public func fetchUserData(userID: String) async throws -> UserBrowseData {
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
            let counts = try? await followService.fetchFollowCounts(for: userID)
            let data = UserBrowseData(
                profile: profile,
                cats: [],
                encounters: [],
                followerCount: counts?.followers ?? 0,
                followingCount: counts?.following ?? 0,
                fetchedAt: Date()
            )
            cache[userID] = data
            return data
        }

        do {
            async let cats = catRepository.fetchAll(ownerID: userID)
            async let encounters = encounterRepository.fetchAll(ownerID: userID)
            async let counts = followService.fetchFollowCounts(for: userID)

            let fetchedCounts = try? await counts
            let data = UserBrowseData(
                profile: profile,
                cats: try await cats,
                encounters: try await encounters,
                followerCount: fetchedCounts?.followers ?? 0,
                followingCount: fetchedCounts?.following ?? 0,
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

    public func cachedData(for userID: String) -> UserBrowseData? {
        guard let cached = cache[userID], !cached.isExpired else { return nil }
        return cached
    }

    public func fetchDisplayName(userID: String) async -> String? {
        if let cached = displayNameCache[userID] {
            return cached
        }

        guard let profile = try? await cloudKitService.fetchUserProfile(appleUserID: userID) else {
            return nil
        }

        displayNameCache[userID] = profile.displayName
        return profile.displayName
    }

    public func cachedDisplayName(for userID: String) -> String? {
        displayNameCache[userID]
    }

    public func batchFetchDisplayNames(userIDs: [String]) async -> [String: String] {
        let uncachedIDs = userIDs.filter { displayNameCache[$0] == nil }

        if !uncachedIDs.isEmpty {
            await withTaskGroup(of: (String, String?).self) { group in
                for userID in uncachedIDs {
                    group.addTask { [cloudKitService] in
                        let profile = try? await cloudKitService.fetchUserProfile(appleUserID: userID)
                        return (userID, profile?.displayName)
                    }
                }

                for await (userID, name) in group {
                    if let name {
                        displayNameCache[userID] = name
                    }
                }
            }
        }

        var result: [String: String] = [:]
        for userID in userIDs {
            if let name = displayNameCache[userID] {
                result[userID] = name
            }
        }
        return result
    }

    public func fetchProfile(userID: String) async -> CloudUserProfile? {
        if let cached = cache[userID], !cached.isExpired {
            return cached.profile
        }

        guard let profile = try? await cloudKitService.fetchUserProfile(appleUserID: userID) else {
            return nil
        }

        displayNameCache[userID] = profile.displayName
        return profile
    }

    public func clearCache() {
        cache.removeAll()
        displayNameCache.removeAll()
    }

    // MARK: - Debug Seeding

    #if DEBUG && canImport(UIKit)
    public func seedFakeUsers() {
        let seed = UserBrowseSeedData.generate()
        cache.merge(seed.cache) { _, new in new }
        displayNameCache.merge(seed.displayNames) { _, new in new }
    }
    #endif
}
