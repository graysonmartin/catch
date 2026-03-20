import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: CatchSpacing.space16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(CatchTheme.primary.opacity(0.6))
            FishBoneSeparator()
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
                        .padding(.horizontal, CatchSpacing.space24)
                        .padding(.vertical, CatchSpacing.space10)
                        .background(CatchTheme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusSmall))
                }
                .padding(.top, CatchSpacing.space4)
            }
        }
        .padding(CatchSpacing.space40)
    }
}
