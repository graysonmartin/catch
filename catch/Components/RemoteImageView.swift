import SwiftUI

struct RemoteImageView<Placeholder: View>: View {
    private let urlString: String
    private let cacheKey: String
    private let placeholder: Placeholder
    private let useFitMode: Bool

    @State private var uiImage: UIImage?
    @State private var isFailed = false

    /// - Parameters:
    ///   - urlString: The remote URL to load.
    ///   - cacheKey: Stable identifier for caching. Defaults to `urlString`.
    ///     Pass a fixed key when the URL varies for the same logical image (signed URLs, expiring tokens).
    ///   - useFitMode: Use `.fit` instead of `.fill` content mode.
    ///   - placeholder: View shown while loading or on failure.
    init(
        urlString: String,
        cacheKey: String? = nil,
        useFitMode: Bool = false,
        @ViewBuilder placeholder: () -> Placeholder
    ) {
        self.urlString = urlString
        self.cacheKey = cacheKey ?? urlString
        self.useFitMode = useFitMode
        self.placeholder = placeholder()
        // Check cache synchronously to avoid flicker
        _uiImage = State(initialValue: RemoteImageCache.shared.memoryImage(for: self.cacheKey))
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
            uiImage = RemoteImageCache.shared.memoryImage(for: cacheKey)
            isFailed = false
        }
        .task(id: urlString) {
            if uiImage != nil { return }
            isFailed = false
            if let downloaded = await RemoteImageCache.shared.loadImage(for: urlString, cacheKey: cacheKey) {
                uiImage = downloaded
            } else {
                isFailed = true
            }
        }
    }
}
