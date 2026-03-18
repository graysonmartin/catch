import Foundation
import Supabase

@MainActor
public final class DefaultSupabaseProfileRepository: SupabaseProfileRepository, @unchecked Sendable {
    private let clientProvider: any SupabaseClientProviding
    private static let tableName = "profiles"
    private static let batchChunkSize = 100

    public init(clientProvider: any SupabaseClientProviding) {
        self.clientProvider = clientProvider
    }

    // MARK: - SupabaseProfileRepository

    public func fetchProfile(id: String) async throws -> SupabaseProfile? {
        let response: [SupabaseProfile] = try await clientProvider.client
            .from(Self.tableName)
            .select()
            .eq("id", value: id)
            .limit(1)
            .execute()
            .value
        return response.first
    }

    public func fetchProfiles(ids: [String]) async throws -> [SupabaseProfile] {
        guard !ids.isEmpty else { return [] }

        var allProfiles: [SupabaseProfile] = []
        for chunk in ids.chunked(into: Self.batchChunkSize) {
            let profiles: [SupabaseProfile] = try await clientProvider.client
                .from(Self.tableName)
                .select()
                .in("id", values: chunk)
                .execute()
                .value
            allProfiles.append(contentsOf: profiles)
        }
        return allProfiles
    }

    public func createProfile(_ payload: SupabaseProfilePayload, id: String) async throws -> SupabaseProfile {
        let insertPayload = SupabaseProfileInsertPayload(id: id, profile: payload)

        let profile: SupabaseProfile = try await clientProvider.client
            .from(Self.tableName)
            .insert(insertPayload)
            .select()
            .single()
            .execute()
            .value
        return profile
    }

    public func updateProfile(id: String, _ payload: SupabaseProfilePayload) async throws -> SupabaseProfile {
        let profile: SupabaseProfile = try await clientProvider.client
            .from(Self.tableName)
            .update(payload)
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value
        return profile
    }

    public func searchUsers(query: String) async throws -> [SupabaseProfile] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return [] }

        let pattern = "%\(trimmed)%"
        let profiles: [SupabaseProfile] = try await clientProvider.client
            .from(Self.tableName)
            .select()
            .or("username.ilike.\(pattern),display_name.ilike.\(pattern)")
            .limit(20)
            .execute()
            .value
        return profiles
    }

    public func checkUsernameAvailability(_ username: String) async throws -> Bool {
        let results: [SupabaseProfile] = try await clientProvider.client
            .from(Self.tableName)
            .select()
            .eq("username", value: username.lowercased())
            .limit(1)
            .execute()
            .value
        return results.isEmpty
    }
}

// MARK: - Array Chunking

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
