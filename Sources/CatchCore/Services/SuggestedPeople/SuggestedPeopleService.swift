import Foundation
import Observation

/// A lightweight model representing a suggested user for discovery.
public struct SuggestedPerson: Sendable, Identifiable {
    public let id: String
    public let displayName: String
    public let username: String?
    public let avatarURL: String?
    public let catCount: Int
    public let isPrivate: Bool

    public init(
        id: String,
        displayName: String,
        username: String?,
        avatarURL: String?,
        catCount: Int,
        isPrivate: Bool
    ) {
        self.id = id
        self.displayName = displayName
        self.username = username
        self.avatarURL = avatarURL
        self.catCount = catCount
        self.isPrivate = isPrivate
    }
}

/// Fetches recently-active public users for the "suggested people" feed section.
@Observable
@MainActor
public final class SuggestedPeopleService: @unchecked Sendable {
    /// Filtered list — excludes already-followed users. Use in Find People.
    public var suggestedPeople: [SuggestedPerson] {
        let excluded = followedIDsProvider()
        return fetchedPeople.filter { !excluded.contains($0.id) }
    }

    /// Unfiltered list — includes followed users. Use for feed cards.
    public var allFetchedPeople: [SuggestedPerson] {
        fetchedPeople
    }

    private var fetchedPeople: [SuggestedPerson] = []
    public private(set) var isLoading = false
    public private(set) var hasLoaded = false

    private let profileRepository: any SupabaseProfileRepository
    private let catRepository: any CatRepository
    private let currentUserIDProvider: () -> String?
    private let followedIDsProvider: () -> Set<String>

    private static let suggestedLimit = 8

    public init(
        profileRepository: any SupabaseProfileRepository,
        catRepository: any CatRepository,
        currentUserIDProvider: @escaping () -> String?,
        followedIDsProvider: @escaping () -> Set<String>
    ) {
        self.profileRepository = profileRepository
        self.catRepository = catRepository
        self.currentUserIDProvider = currentUserIDProvider
        self.followedIDsProvider = followedIDsProvider
    }

    /// Loads suggested people if not already loaded. Safe to call multiple times.
    public func loadIfNeeded() async {
        guard !hasLoaded, !isLoading else { return }
        await load()
    }

    /// Forces a fresh fetch of suggested people.
    public func load() async {
        isLoading = true
        defer {
            isLoading = false
            hasLoaded = true
        }

        let excludedIDs = buildExcludedIDs()

        do {
            let profiles = try await profileRepository.fetchRecentPublicUsers(
                excluding: excludedIDs,
                limit: Self.suggestedLimit
            )

            let userIDs = profiles.map { $0.id.uuidString.lowercased() }
            let catCounts = await fetchCatCounts(for: userIDs)

            fetchedPeople = profiles.map { profile in
                let userID = profile.id.uuidString.lowercased()
                return SuggestedPerson(
                    id: userID,
                    displayName: profile.displayName,
                    username: profile.username.isEmpty ? nil : profile.username,
                    avatarURL: profile.avatarUrl,
                    catCount: catCounts[userID] ?? 0,
                    isPrivate: profile.isPrivate
                )
            }
        } catch {
            fetchedPeople = []
        }
    }

    /// Removes a person from the local suggestions list (e.g. after following them).
    public func removeSuggestion(id: String) {
        fetchedPeople.removeAll { $0.id == id }
    }

    // MARK: - Private

    private func buildExcludedIDs() -> Set<String> {
        var excluded = followedIDsProvider()
        if let currentID = currentUserIDProvider() {
            excluded.insert(currentID)
        }
        return excluded
    }

    private func fetchCatCounts(for userIDs: [String]) async -> [String: Int] {
        guard !userIDs.isEmpty else { return [:] }
        return (try? await catRepository.fetchCatCounts(ownerIDs: userIDs)) ?? [:]
    }
}
