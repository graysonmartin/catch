import UIKit

/// Resizes images before upload to reduce file size and bandwidth.
enum ImageResizer {

    /// Maximum pixel dimension for cat and encounter photos.
    static let photoMaxDimension: CGFloat = 1200

    /// Maximum pixel dimension for avatar/profile photos.
    static let avatarMaxDimension: CGFloat = 400

    /// Maximum pixel dimension for thumbnail variants uploaded alongside full images.
    static let thumbnailMaxDimension: CGFloat = 300

    /// Resizes an image so its longest edge fits within `maxDimension` pixels.
    /// Returns the original image if it's already within bounds.
    static func resize(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let longestEdge = max(size.width, size.height)
        guard longestEdge > maxDimension else { return image }

        let scale = maxDimension / longestEdge
        let newSize = CGSize(
            width: (size.width * scale).rounded(.down),
            height: (size.height * scale).rounded(.down)
        )

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
