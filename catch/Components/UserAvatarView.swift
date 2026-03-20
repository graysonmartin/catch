import SwiftUI
import CatchCore

/// Displays a user avatar from a remote URL, falling back to a system person icon.
/// Used in list rows (follow lists, search results, pending requests, comments).
struct UserAvatarView: View {
    let avatarURL: String?
    var size: CGFloat = 36
    var accessibilityName: String?

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
        .accessibilityLabel(
            accessibilityName.map { CatchStrings.Accessibility.userAvatar(name: $0) }
                ?? CatchStrings.Accessibility.userAvatarPlaceholder
        )
    }

    private var placeholder: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundStyle(CatchTheme.secondary)
    }
}
