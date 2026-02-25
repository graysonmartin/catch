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
}
