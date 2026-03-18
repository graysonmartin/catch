import Foundation

/// Represents a photo in an edit flow — either local data not yet uploaded,
/// or a remote URL already stored on the server.
public struct PhotoItem: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let content: Content

    public enum Content: Equatable, Sendable {
        case local(Data)
        case remote(String)
    }

    public init(id: UUID = UUID(), content: Content) {
        self.id = id
        self.content = content
    }

    public static func local(_ data: Data) -> PhotoItem {
        PhotoItem(content: .local(data))
    }

    public static func remote(_ url: String) -> PhotoItem {
        PhotoItem(content: .remote(url))
    }
}

extension Array where Element == PhotoItem {
    /// Extracts only the local photo data, preserving order.
    public var localData: [Data] {
        compactMap { item in
            if case .local(let data) = item.content { return data }
            return nil
        }
    }

    /// Extracts only the remote URLs, preserving order.
    public var remoteUrls: [String] {
        compactMap { item in
            if case .remote(let url) = item.content { return url }
            return nil
        }
    }
}
