import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Supabase

/// Downloads photos from CloudKit asset URLs and uploads them to Supabase Storage.
public final class PhotoMigrator {
    private let supabase: SupabaseClient
    private let urlSession: URLSession
    private let isDryRun: Bool

    public init(supabase: SupabaseClient, isDryRun: Bool = false) {
        self.supabase = supabase
        self.urlSession = URLSession.shared
        self.isDryRun = isDryRun
    }

    /// Migrates a list of CloudKit photo URLs to Supabase Storage.
    /// Returns the new Supabase public URLs.
    public func migratePhotos(
        urls: [String],
        bucket: String,
        ownerID: String,
        entityID: String
    ) async throws -> [String] {
        guard !urls.isEmpty else { return [] }

        if isDryRun {
            MigrationLogger.info("  [dry-run] Would migrate \(urls.count) photo(s) to \(bucket)/\(ownerID)/\(entityID)/")
            return urls.map { _ in "https://placeholder.supabase.co/dry-run-photo" }
        }

        var migratedURLs: [String] = []
        for (index, urlString) in urls.enumerated() {
            let photoData = try await downloadPhoto(from: urlString)
            let fileName = "\(entityID)_\(index).jpg"
            let path = "\(ownerID)/\(fileName)"

            try await supabase.storage
                .from(bucket)
                .upload(
                    path,
                    data: photoData,
                    options: FileOptions(
                        contentType: "image/jpeg",
                        upsert: true
                    )
                )

            let publicURL = try supabase.storage
                .from(bucket)
                .getPublicURL(path: path)
                .absoluteString

            migratedURLs.append(publicURL)
        }
        return migratedURLs
    }

    /// Downloads photo data from a URL.
    private func downloadPhoto(from urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw MigrationError.photoDownloadFailed(url: urlString, reason: "invalid URL")
        }
        let (data, response) = try await urlSession.data(from: url)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw MigrationError.photoDownloadFailed(
                url: urlString,
                reason: "HTTP \(httpResponse.statusCode)"
            )
        }
        return data
    }
}
