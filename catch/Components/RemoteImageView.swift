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
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task(id: urlString) {
            if let cached = RemoteImageCache.shared.image(for: urlString) {
                uiImage = cached
                return
            }
            uiImage = nil
            isFailed = false
            guard let url = URL(string: urlString) else {
                isFailed = true
                return
            }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let downloaded = UIImage(data: data) else {
                    isFailed = true
                    return
                }
                RemoteImageCache.shared.setImage(downloaded, for: urlString)
                uiImage = downloaded
            } catch {
                if !(error is CancellationError) {
                    isFailed = true
                }
            }
        }
    }
}
