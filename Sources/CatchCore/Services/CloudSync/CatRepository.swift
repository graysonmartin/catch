import Foundation

@MainActor
public protocol CatRepository: Observable, Sendable {
    func save(_ payload: CatSyncPayload, ownerID: String) async throws -> String
    func delete(recordName: String) async throws
    func fetchAll(ownerID: String) async throws -> [CloudCat]
}
