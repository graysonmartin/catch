import SwiftUI

/// Shared component for loading remote images via AsyncImage.
/// Displays a loading indicator while fetching, and a placeholder on failure.
struct RemoteImageView<Placeholder: View>: View {
    private let urlString: String
    private let placeholder: Placeholder

    init(urlString: String, @ViewBuilder placeholder: () -> Placeholder) {
        self.urlString = urlString
        self.placeholder = placeholder()
    }

    var body: some View {
        if let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    placeholder
                default:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        } else {
            placeholder
        }
    }
}
