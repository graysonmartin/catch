import SwiftUI

struct CatPhotoView: View {
    let photoData: Data?
    var photoUrl: String?
    var size: CGFloat = 80

    var body: some View {
        Group {
            if let data = photoData,
               let uiImage = ImageDownsampler.shared.downsample(data: data, to: CGSize(width: size, height: size)) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else if let photoUrl {
                RemoteImageView(urlString: photoUrl) { placeholder }
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
