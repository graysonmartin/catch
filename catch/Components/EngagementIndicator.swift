import SwiftUI
import CatchCore

struct EngagementIndicator: View {
    let likeCount: Int
    let commentCount: Int

    private var hasEngagement: Bool {
        likeCount > 0 || commentCount > 0
    }

    var body: some View {
        if hasEngagement {
            HStack(spacing: CatchSpacing.space8) {
                if likeCount > 0 {
                    Label("\(likeCount)", systemImage: "heart.fill")
                        .font(.caption2)
                        .foregroundStyle(CatchTheme.primary)
                }
                if commentCount > 0 {
                    Label("\(commentCount)", systemImage: "bubble.right.fill")
                        .font(.caption2)
                        .foregroundStyle(CatchTheme.textSecondary)
                }
            }
        }
    }
}
