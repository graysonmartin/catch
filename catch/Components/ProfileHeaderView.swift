import SwiftUI

struct ProfileHeaderView: View {
    let data: ProfileDisplayData
    let avatarSize: CGFloat

    init(data: ProfileDisplayData, avatarSize: CGFloat = 120) {
        self.data = data
        self.avatarSize = avatarSize
    }

    var body: some View {
        VStack(spacing: CatchSpacing.space8) {
            avatarImage

            Text(data.displayName.isEmpty ? CatchStrings.Profile.mysteriousStranger : data.displayName)
                .font(.title2.weight(.bold))
                .foregroundStyle(CatchTheme.textPrimary)

            if let username = data.username, !username.isEmpty {
                Text(UsernameValidator.formatDisplay(username))
                    .font(.subheadline)
                    .foregroundStyle(CatchTheme.primary)
            }

            Text(data.bio.isEmpty ? CatchStrings.Profile.tooCoolForBio : data.bio)
                .font(.subheadline)
                .foregroundStyle(CatchTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, CatchSpacing.space32)
        }
    }

    // MARK: - Avatar

    @ViewBuilder
    private var avatarImage: some View {
        if let imageData = data.avatarData, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: avatarSize, height: avatarSize)
                .clipShape(Circle())
        } else {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: avatarSize, height: avatarSize)
                .foregroundStyle(CatchTheme.secondary)
        }
    }
}
