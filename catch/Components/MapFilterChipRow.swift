import SwiftUI
import CatchCore

struct MapFilterChipRow: View {
    @Binding var filterState: MapFilterState

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: CatchSpacing.space8) {
                ownerChip(.myCats, label: CatchStrings.Map.myCats, icon: "person.fill")
                ownerChip(.friendsCats, label: CatchStrings.Map.friendsCats, icon: "person.2.fill")

                Divider()
                    .frame(height: 24)

                timeRangeChip(.last7Days, label: CatchStrings.Map.last7Days)
                timeRangeChip(.last30Days, label: CatchStrings.Map.last30Days)
                timeRangeChip(.allTime, label: CatchStrings.Map.allTime)

                if filterState.hasActiveFilters {
                    resetButton
                }
            }
            .padding(.horizontal, CatchSpacing.space12)
            .padding(.vertical, CatchSpacing.space6)
        }
    }

    // MARK: - Private

    @ViewBuilder
    private func ownerChip(_ filter: MapOwnerFilter, label: String, icon: String) -> some View {
        let isSelected = filterState.ownerFilters.contains(filter)
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                filterState.toggleOwnerFilter(filter)
            }
        } label: {
            HStack(spacing: CatchSpacing.space4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(label)
                    .font(.caption.weight(.medium))
            }
            .chipStyle(isSelected: isSelected)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func timeRangeChip(_ range: MapTimeRange, label: String) -> some View {
        let isSelected = filterState.timeRange == range
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                filterState.timeRange = range
            }
        } label: {
            Text(label)
                .font(.caption.weight(.medium))
                .chipStyle(isSelected: isSelected)
        }
        .buttonStyle(.plain)
    }

    private var resetButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                filterState.reset()
            }
        } label: {
            HStack(spacing: CatchSpacing.space4) {
                Image(systemName: "xmark")
                    .font(.caption2)
                Text(CatchStrings.Map.resetFilters)
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, CatchSpacing.space10)
            .padding(.vertical, CatchSpacing.space6)
            .background(CatchTheme.textSecondary.opacity(0.15))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Chip style modifier

private struct ChipStyleModifier: ViewModifier {
    let isSelected: Bool

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, CatchSpacing.space10)
            .padding(.vertical, CatchSpacing.space6)
            .foregroundStyle(isSelected ? .white : CatchTheme.textPrimary)
            .background(isSelected ? CatchTheme.primary : CatchTheme.textSecondary.opacity(0.1))
            .clipShape(Capsule())
    }
}

private extension View {
    func chipStyle(isSelected: Bool) -> some View {
        modifier(ChipStyleModifier(isSelected: isSelected))
    }
}
