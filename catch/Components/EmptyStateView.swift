import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(CatchTheme.primary.opacity(0.6))
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(CatchTheme.textPrimary)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(CatchTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}
