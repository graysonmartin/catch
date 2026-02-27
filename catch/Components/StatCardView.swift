import SwiftUI

struct StatCardView: View {
    let count: Int
    let label: String
    let icon: String
    let showChevron: Bool

    init(count: Int, label: String, icon: String, showChevron: Bool = false) {
        self.count = count
        self.label = label
        self.icon = icon
        self.showChevron = showChevron
    }

    var body: some View {
        VStack(spacing: CatchSpacing.space8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(CatchTheme.primary)

            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(CatchTheme.textPrimary)

            Text(label)
                .font(.caption)
                .foregroundStyle(CatchTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, CatchSpacing.space16)
        .background(CatchTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadius))
        .shadow(
            color: .black.opacity(CatchTheme.cardShadowOpacity),
            radius: CatchTheme.cardShadowRadius,
            y: CatchTheme.cardShadowY
        )
        .overlay(alignment: .bottomTrailing) {
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(CatchTheme.textSecondary)
                    .padding(CatchSpacing.space8)
            }
        }
    }
}
