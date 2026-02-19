import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil

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

            if let actionLabel, let action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(CatchTheme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, 4)
            }
        }
        .padding(40)
    }
}
