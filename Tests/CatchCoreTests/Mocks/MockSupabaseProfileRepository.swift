import Foundation
import Observation
@testable import CatchCore

@Observable
@MainActor
final class MockSupabaseProfileRepository: SupabaseProfileRepository {
    var fetchProfileCalls: [String] = []
    var fetchProfilesCalls: [[String]] = []
    var createProfileCalls: [(payload: SupabaseProfilePayload, id: String)] = []
    var updateProfileCalls: [(id: String, payload: SupabaseProfilePayload)] = []
    var upsertProfileCalls: [(payload: SupabaseProfilePayload, id: String)] = []
    var searchUsersCalls: [String] = []
    var checkUsernameCalls: [String] = []
    var fetchRecentPublicUsersCalls: [(excludedIDs: Set<String>, limit: Int)] = []

    var fetchProfileResult: SupabaseProfile?
    var fetchProfileResultsByID: [String: SupabaseProfile] = [:]
    var fetchProfilesResult: [SupabaseProfile] = []
    var fetchProfileError: (any Error)?
    var createProfileResult: SupabaseProfile?
    var updateProfileResult: SupabaseProfile?
    var upsertProfileResult: SupabaseProfile?
    var searchUsersResult: [SupabaseProfile] = []
    var usernameAvailabilityResult: Bool = true
    var fetchRecentPublicUsersResult: [SupabaseProfile] = []

    func fetchProfile(id: String) async throws -> SupabaseProfile? {
        fetchProfileCalls.append(id)
        if let error = fetchProfileError { throw error }
        return fetchProfileResultsByID[id] ?? fetchProfileResult
    }

    func fetchProfiles(ids: [String]) async throws -> [SupabaseProfile] {
        fetchProfilesCalls.append(ids)
        if let error = fetchProfileError { throw error }
        return fetchProfilesResult
    }

    func createProfile(_ payload: SupabaseProfilePayload, id: String) async throws -> SupabaseProfile {
        createProfileCalls.append((payload, id))
        guard let result = createProfileResult else {
            throw NSError(domain: "MockSupabaseProfileRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "no stubbed create result"])
        }
        return result
    }

    func updateProfile(id: String, _ payload: SupabaseProfilePayload) async throws -> SupabaseProfile {
        updateProfileCalls.append((id, payload))
        guard let result = updateProfileResult else {
            throw NSError(domain: "MockSupabaseProfileRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "no stubbed update result"])
        }
        return result
    }

    func upsertProfile(_ payload: SupabaseProfilePayload, id: String) async throws -> SupabaseProfile {
        upsertProfileCalls.append((payload, id))
        if let error = fetchProfileError { throw error }
        guard let result = upsertProfileResult else {
            return SupabaseProfile.fixture(displayName: payload.displayName, username: payload.username)
        }
        return result
    }

    func searchUsers(query: String) async throws -> [SupabaseProfile] {
        searchUsersCalls.append(query)
        return searchUsersResult
    }

    func checkUsernameAvailability(_ username: String) async throws -> Bool {
        checkUsernameCalls.append(username)
        return usernameAvailabilityResult
    }

    func fetchRecentPublicUsers(excluding excludedIDs: Set<String>, limit: Int) async throws -> [SupabaseProfile] {
        fetchRecentPublicUsersCalls.append((excludedIDs, limit))
        if let error = fetchProfileError { throw error }
        return fetchRecentPublicUsersResult
            .filter { !excludedIDs.contains($0.id.uuidString.lowercased()) }
            .prefix(limit)
            .map { $0 }
    }

    func reset() {
        fetchProfileCalls = []
        fetchProfilesCalls = []
        createProfileCalls = []
        updateProfileCalls = []
        upsertProfileCalls = []
        searchUsersCalls = []
        checkUsernameCalls = []
        fetchRecentPublicUsersCalls = []
        fetchProfileResult = nil
        fetchProfileResultsByID = [:]
        fetchProfilesResult = []
        fetchProfileError = nil
        createProfileResult = nil
        updateProfileResult = nil
        upsertProfileResult = nil
        searchUsersResult = []
        usernameAvailabilityResult = true
        fetchRecentPublicUsersResult = []
    }
}

// MARK: - Shared Test Factory

extension SupabaseProfile {
    static func fixture(
        id: UUID = UUID(),
        displayName: String = "test",
        username: String = "test_user",
        bio: String = "",
        isPrivate: Bool = false,
        avatarUrl: String? = nil,
        followerCount: Int = 0,
        followingCount: Int = 0
    ) -> SupabaseProfile {
        SupabaseProfile(
            id: id,
            displayName: displayName,
            username: username,
            bio: bio,
            isPrivate: isPrivate,
            showCats: true,
            showEncounters: true,
            avatarUrl: avatarUrl,
            followerCount: followerCount,
            followingCount: followingCount,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
