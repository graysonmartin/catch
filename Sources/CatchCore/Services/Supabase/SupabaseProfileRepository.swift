import Foundation

@MainActor
public protocol SupabaseProfileRepository: Sendable {
    func fetchProfile(id: String) async throws -> SupabaseProfile?
    func fetchProfiles(ids: [String]) async throws -> [SupabaseProfile]
    func createProfile(_ payload: SupabaseProfilePayload, id: String) async throws -> SupabaseProfile
    func updateProfile(id: String, _ payload: SupabaseProfilePayload) async throws -> SupabaseProfile
    func searchUsers(query: String) async throws -> [SupabaseProfile]
    func checkUsernameAvailability(_ username: String) async throws -> Bool
}
