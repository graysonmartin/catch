import SwiftUI

struct RemoteImageView<Placeholder: View>: View {
    private let urlString: String
    private let placeholder: Placeholder
    private let useFitMode: Bool

    @State private var uiImage: UIImage?
    @State private var isFailed = false

    init(urlString: String, useFitMode: Bool = false, @ViewBuilder placeholder: () -> Placeholder) {
        self.urlString = urlString
        self.useFitMode = useFitMode
        self.placeholder = placeholder()
        // Check cache synchronously to avoid flicker
        _uiImage = State(initialValue: RemoteImageCache.shared.memoryImage(for: urlString))
    }

    var body: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: useFitMode ? .fit : .fill)
            } else if isFailed {
                placeholder
            } else {
                placeholder
            }
        }
        .onChange(of: urlString) {
            uiImage = RemoteImageCache.shared.memoryImage(for: urlString)
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
