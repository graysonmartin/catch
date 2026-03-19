import Foundation

/// Derives thumbnail URLs from full image URLs using a naming convention.
///
/// Full:  `.../photos/abc123.jpg`
/// Thumb: `.../photos/abc123_thumb.jpg`
public enum ThumbnailURL {

    /// Suffix inserted before the file extension for thumbnail variants.
    private static let thumbSuffix = "_thumb"

    /// Returns a thumbnail URL by inserting `_thumb` before the file extension.
    /// Returns `nil` if the URL has no recognizable image extension.
    ///
    /// Example:
    /// ```
    /// thumbnailURL(for: "https://example.com/photo.jpg")
    /// // → "https://example.com/photo_thumb.jpg"
    /// ```
    public static func thumbnailURL(for urlString: String) -> String? {
        // Split off query/fragment if present
        let (basePath, suffix) = splitQueryFragment(urlString)

        // Find the last path separator to isolate the filename
        guard let lastSlash = basePath.lastIndex(of: "/") else {
            return insertThumbSuffix(in: basePath, suffix: suffix)
        }

        let filename = basePath[basePath.index(after: lastSlash)...]
        guard let dotIndex = filename.lastIndex(of: ".") else { return nil }

        let beforeExt = basePath[basePath.startIndex..<dotIndex]
        let ext = basePath[dotIndex...]

        return "\(beforeExt)\(thumbSuffix)\(ext)\(suffix)"
    }

    private static func insertThumbSuffix(in path: String, suffix: String) -> String? {
        guard let dotIndex = path.lastIndex(of: ".") else { return nil }
        return "\(path[path.startIndex..<dotIndex])\(thumbSuffix)\(path[dotIndex...])\(suffix)"
    }

    /// Returns the thumbnail URL if available, otherwise returns the original URL.
    /// Use this as the default display URL for small image contexts.
    public static func thumbnailOrOriginal(for urlString: String) -> String {
        thumbnailURL(for: urlString) ?? urlString
    }

    // MARK: - Private

    /// Splits a URL string into (path, queryAndFragment).
    /// E.g., "https://a.com/b.jpg?token=x" → ("https://a.com/b.jpg", "?token=x")
    private static func splitQueryFragment(_ urlString: String) -> (String, String) {
        if let queryStart = urlString.firstIndex(of: "?") {
            return (String(urlString[..<queryStart]), String(urlString[queryStart...]))
        }
        if let fragmentStart = urlString.firstIndex(of: "#") {
            return (String(urlString[..<fragmentStart]), String(urlString[fragmentStart...]))
        }
        return (urlString, "")
    }
}
