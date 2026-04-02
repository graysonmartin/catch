import SwiftUI
import CatchCore

struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: CatchSpacing.space8) {
            Image(systemName: "wifi.slash")
                .font(.caption.weight(.semibold))
            Text(CatchStrings.Network.offlineBanner)
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(.white)
        .padding(.vertical, CatchSpacing.space8)
        .frame(maxWidth: .infinity)
        .background(CatchTheme.textSecondary.opacity(0.85))
    }
}
