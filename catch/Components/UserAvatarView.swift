import SwiftUI

/// Displays a user avatar from a remote URL, falling back to a system person icon.
/// Used in list rows (follow lists, search results, pending requests, comments).
struct UserAvatarView: View {
    let avatarURL: String?
    var size: CGFloat = 36

    var body: some View {
        Group {
            if let url = avatarURL, !url.isEmpty {
                RemoteImageView(urlString: url) {
                    placeholder
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else {
                placeholder
            }
        }
    }

    private var placeholder: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundStyle(CatchTheme.secondary)
    }
}
