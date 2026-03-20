import SwiftUI
import CatchCore

struct CatPhotoView: View {
    let photoData: Data?
    var photoUrl: String?
    var size: CGFloat = 80
    /// When true, loads the thumbnail variant URL for bandwidth savings.
    /// Set to false when displaying in contexts that need full resolution.
    var useThumbnail: Bool = true
    /// Accessibility label for VoiceOver. When nil, uses a generic placeholder label.
    var accessibilityName: String?

    /// Resolves to thumbnail URL when appropriate, otherwise the original.
    private var resolvedUrl: String? {
        guard let photoUrl else { return nil }
        return useThumbnail ? ThumbnailURL.thumbnailOrOriginal(for: photoUrl) : photoUrl
    }

    /// Original URL used as fallback when thumbnail doesn't exist on the server.
    private var fallbackUrl: String? {
        guard useThumbnail, let photoUrl, resolvedUrl != photoUrl else { return nil }
        return photoUrl
    }

    var body: some View {
        Group {
            if let data = photoData,
               let uiImage = ImageDownsampler.shared.downsample(data: data, to: CGSize(width: size, height: size)) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else if let url = resolvedUrl {
                RemoteImageView(urlString: url, fallbackUrlString: fallbackUrl) { placeholder }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusSmall))
        .accessibilityLabel(
            accessibilityName.map { CatchStrings.Accessibility.catPhoto(name: $0) }
                ?? CatchStrings.Accessibility.catPhotoPlaceholder
        )
    }

    private var placeholder: some View {
        Image(systemName: "pawprint.fill")
            .font(.system(size: size * 0.4))
            .foregroundStyle(CatchTheme.primary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(CatchTheme.secondary.opacity(0.3))
    }
}
