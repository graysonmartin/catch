import SwiftUI

struct RemoteImageView<Placeholder: View>: View {
    private let urlString: String
    private let fallbackUrlString: String?
    private let cacheKey: String
    private let placeholder: Placeholder
    private let useFitMode: Bool

    @State private var uiImage: UIImage?
    @State private var isFailed = false

    /// - Parameters:
    ///   - urlString: The remote URL to load.
    ///   - fallbackUrlString: A secondary URL to try if `urlString` fails (e.g. original URL when primary is a thumbnail).
    ///   - cacheKey: Stable identifier for caching. Defaults to `urlString`.
    ///     Pass a fixed key when the URL varies for the same logical image (signed URLs, expiring tokens).
    ///   - useFitMode: Use `.fit` instead of `.fill` content mode.
    ///   - placeholder: View shown while loading or on failure.
    init(
        urlString: String,
        fallbackUrlString: String? = nil,
        cacheKey: String? = nil,
        useFitMode: Bool = false,
        @ViewBuilder placeholder: () -> Placeholder
    ) {
        self.urlString = urlString
        self.fallbackUrlString = fallbackUrlString
        self.cacheKey = cacheKey ?? urlString
        self.useFitMode = useFitMode
        self.placeholder = placeholder()
        // Check cache synchronously to avoid flicker
        let initial = RemoteImageCache.shared.memoryImage(for: cacheKey ?? urlString)
            ?? fallbackUrlString.flatMap { RemoteImageCache.shared.memoryImage(for: $0) }
        _uiImage = State(initialValue: initial)
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
                ?? fallbackUrlString.flatMap { RemoteImageCache.shared.memoryImage(for: $0) }
            isFailed = false
        }
        .task(id: urlString) {
            if uiImage != nil { return }
            isFailed = false
            if let downloaded = await RemoteImageCache.shared.loadImage(for: urlString, cacheKey: cacheKey) {
                uiImage = downloaded
            } else if let fallback = fallbackUrlString,
                      let downloaded = await RemoteImageCache.shared.loadImage(for: fallback) {
                uiImage = downloaded
            } else {
                isFailed = true
            }
        }
    }
}
