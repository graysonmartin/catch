import SwiftUI
import CatchCore

struct BreedRarityBadge: View {
    let rarity: BreedRarity

    var body: some View {
        Text(rarity.label)
            .font(.caption2.weight(.bold))
            .textCase(.uppercase)
            .tracking(0.5)
            .foregroundStyle(.white)
            .padding(.horizontal, CatchSpacing.space6)
            .padding(.vertical, CatchSpacing.space2)
            .background(rarity.color, in: Capsule())
    }
}
