import SwiftUI
import CatchCore

struct CatPhotoView: View {
    let photoData: Data?
    var photoUrl: String?
    var size: CGFloat = 80
    /// When true, loads the thumbnail variant URL for bandwidth savings.
    /// Set to false when displaying in contexts that need full resolution.
    var useThumbnail: Bool = true

    /// Resolves to thumbnail URL when appropriate, otherwise the original.
    private var resolvedUrl: String? {
        guard let photoUrl else { return nil }
        return useThumbnail ? ThumbnailURL.thumbnailOrOriginal(for: photoUrl) : photoUrl
    }

    var body: some View {
        Group {
            if let data = photoData,
               let uiImage = ImageDownsampler.shared.downsample(data: data, to: CGSize(width: size, height: size)) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else if let url = resolvedUrl {
                RemoteImageView(urlString: url) { placeholder }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusSmall))
    }

    private var placeholder: some View {
        Image(systemName: "pawprint.fill")
            .font(.system(size: size * 0.4))
            .foregroundStyle(CatchTheme.primary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(CatchTheme.secondary.opacity(0.3))
    }
}
