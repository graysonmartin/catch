import SwiftUI

struct BreedRarityBadge: View {
    let rarity: BreedRarity

    var body: some View {
        Text(rarity.label)
            .font(.system(size: 9, weight: .bold))
            .textCase(.uppercase)
            .tracking(0.5)
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(rarity.color, in: Capsule())
    }
}
