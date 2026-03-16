import Foundation

/// Handles uploading, deleting, and URL generation for photos in Supabase Storage.
@MainActor
public protocol SupabaseAssetService: Sendable {
    /// Uploads JPEG data to the specified bucket under the user's folder.
    /// Returns the public URL of the uploaded file.
    func uploadPhoto(
        _ data: Data,
        bucket: SupabaseStorageBucket,
        ownerID: String,
        fileName: String
    ) async throws -> String

    /// Uploads multiple JPEG photos and returns their public URLs.
    func uploadPhotos(
        _ photos: [Data],
        bucket: SupabaseStorageBucket,
        ownerID: String
    ) async throws -> [String]

    /// Deletes a photo from storage by its path.
    func deletePhoto(
        bucket: SupabaseStorageBucket,
        path: String
    ) async throws

    /// Builds the public URL for a file in a bucket.
    func publicURL(
        bucket: SupabaseStorageBucket,
        path: String
    ) -> String
}
