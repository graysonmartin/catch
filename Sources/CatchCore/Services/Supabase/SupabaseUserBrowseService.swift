import Foundation
import Observation

@Observable
@MainActor
public final class SupabaseUserBrowseService: UserBrowseService {
    public private(set) var isLoading = false
    public private(set) var error: UserBrowseError?

    private let profileRepository: any SupabaseProfileRepository
    private let catRepository: any CatRepository
    private let encounterRepository: any EncounterRepository
    private let followService: any FollowService
    private let currentUserIDProvider: () -> String?

    private var cache: [String: UserBrowseData] = [:]
    private var displayNameCache: [String: String] = [:]
    private var profileCache: [String: CloudUserProfile] = [:]

    public init(
        profileRepository: any SupabaseProfileRepository,
        catRepository: any CatRepository,
        encounterRepository: any EncounterRepository,
        followService: any FollowService,
        currentUserIDProvider: @escaping () -> String?
    ) {
        self.profileRepository = profileRepository
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

        guard let supabaseProfile = try await profileRepository.fetchProfile(id: userID) else {
            let browseError = UserBrowseError.userNotFound
            error = browseError
            throw browseError
        }

        let profile = SupabaseProfileMapper.toCloudUserProfile(supabaseProfile)
        displayNameCache[userID] = profile.displayName

        let currentUserID = currentUserIDProvider()
        let isOwnProfile = currentUserID == userID
        let isPrivateAndNotFollowing = profile.isPrivate && !isOwnProfile && !followService.isFollowing(userID)

        if isPrivateAndNotFollowing {
            let data = UserBrowseData(
                profile: profile,
                cats: [],
                encounters: [],
                followerCount: supabaseProfile.followerCount,
                followingCount: supabaseProfile.followingCount,
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
                followerCount: supabaseProfile.followerCount,
                followingCount: supabaseProfile.followingCount,
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

        guard let supabaseProfile = try? await profileRepository.fetchProfile(id: userID) else {
            return nil
        }

        displayNameCache[userID] = supabaseProfile.displayName
        return supabaseProfile.displayName
    }

    public func cachedDisplayName(for userID: String) -> String? {
        displayNameCache[userID]
    }

    public func batchFetchDisplayNames(userIDs: [String]) async -> [String: String] {
        let uncachedIDs = userIDs.filter { displayNameCache[$0] == nil }

        if !uncachedIDs.isEmpty {
            let profiles = (try? await profileRepository.fetchProfiles(ids: uncachedIDs)) ?? []
            for profile in profiles {
                displayNameCache[profile.id.uuidString.lowercased()] = profile.displayName
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

    public func batchFetchProfiles(userIDs: [String]) async -> [String: CloudUserProfile] {
        let uncachedIDs = userIDs.filter { profileCache[$0] == nil && cache[$0] == nil }

        if !uncachedIDs.isEmpty {
            let profiles = (try? await profileRepository.fetchProfiles(ids: uncachedIDs)) ?? []
            for supabaseProfile in profiles {
                let key = supabaseProfile.id.uuidString.lowercased()
                let profile = SupabaseProfileMapper.toCloudUserProfile(supabaseProfile)
                profileCache[key] = profile
                displayNameCache[key] = profile.displayName
            }
        }

        var result: [String: CloudUserProfile] = [:]
        for userID in userIDs {
            if let cached = cache[userID], !cached.isExpired {
                result[userID] = cached.profile
            } else if let cached = profileCache[userID] {
                result[userID] = cached
            }
        }
        return result
    }

    public func fetchProfile(userID: String) async -> CloudUserProfile? {
        if let cached = cache[userID], !cached.isExpired {
            return cached.profile
        }
        if let cached = profileCache[userID] {
            return cached
        }

        guard let supabaseProfile = try? await profileRepository.fetchProfile(id: userID) else {
            return nil
        }

        let profile = SupabaseProfileMapper.toCloudUserProfile(supabaseProfile)
        displayNameCache[userID] = profile.displayName
        profileCache[userID] = profile
        return profile
    }

    public func cachedProfile(for userID: String) -> CloudUserProfile? {
        if let cached = cache[userID], !cached.isExpired {
            return cached.profile
        }
        return profileCache[userID]
    }

    public func invalidateCache(for userID: String) {
        cache.removeValue(forKey: userID)
    }

    public func clearCache() {
        cache.removeAll()
        displayNameCache.removeAll()
        profileCache.removeAll()
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
