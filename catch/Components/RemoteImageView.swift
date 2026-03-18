import SwiftUI

struct RemoteImageView<Placeholder: View>: View {
    private let urlString: String
    private let placeholder: Placeholder

    @State private var uiImage: UIImage?
    @State private var isFailed = false

    init(urlString: String, @ViewBuilder placeholder: () -> Placeholder) {
        self.urlString = urlString
        self.placeholder = placeholder()
        // Check cache synchronously to avoid flicker
        _uiImage = State(initialValue: RemoteImageCache.shared.image(for: urlString))
    }

    var body: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else if isFailed {
                placeholder
            } else {
                placeholder
            }
        }
        .onChange(of: urlString) {
            uiImage = RemoteImageCache.shared.image(for: urlString)
            isFailed = false
        }
        .task(id: urlString) {
            if uiImage != nil { return }
            isFailed = false
            if let downloaded = await RemoteImageCache.shared.loadImage(for: urlString) {
                uiImage = downloaded
            } else {
                isFailed = true
            }
        }
    }
}
