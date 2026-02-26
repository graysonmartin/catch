import SwiftUI

struct PersonalityLabelBadgeView: View {
    let label: String
    private let compact: Bool

    init(_ label: String, compact: Bool = false) {
        self.label = label
        self.compact = compact
    }

    var body: some View {
        Text(label)
            .font(.system(size: compact ? 10 : 12, weight: .medium))
            .foregroundStyle(CatchTheme.primary)
            .padding(.horizontal, compact ? CatchSpacing.space6 : CatchSpacing.space8)
            .padding(.vertical, compact ? CatchSpacing.space2 : CatchSpacing.space4)
            .background(
                Capsule()
                    .fill(CatchTheme.primary.opacity(0.12))
            )
    }
}
