import SwiftUI
import CatchCore

struct CollectionSortFilterBar: View {
    @Binding var activeFilters: Set<CollectionFilter>

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: CatchSpacing.space8) {
                ForEach(CollectionFilter.allCases) { filter in
                    filterPill(for: filter)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, CatchSpacing.space8)
        }
        .contentShape(Rectangle())
    }

    private func filterPill(for filter: CollectionFilter) -> some View {
        let isActive = activeFilters.contains(filter)
        return Button {
            withAnimation(nil) {
                toggleFilter(filter)
            }
        } label: {
            HStack(spacing: CatchSpacing.space4) {
                Image(systemName: filter.icon)
                    .font(.caption2)
                Text(filter.displayName)
                    .font(.caption.weight(.medium))
            }
            .foregroundStyle(isActive ? .white : CatchTheme.textSecondary)
            .padding(.horizontal, CatchSpacing.space12)
            .padding(.vertical, CatchSpacing.space10)
            .background(isActive ? CatchTheme.primary : CatchTheme.cardBackground)
            .clipShape(Capsule())
            .shadow(
                color: .black.opacity(CatchTheme.cardShadowOpacity),
                radius: 2,
                y: 1
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }

    // MARK: - Helpers

    private func toggleFilter(_ filter: CollectionFilter) {
        if activeFilters.contains(filter) {
            activeFilters.remove(filter)
        } else {
            // "Last 7 days" and "Last 30 days" are mutually exclusive
            if filter == .seenLast7Days {
                activeFilters.remove(.seenLast30Days)
            } else if filter == .seenLast30Days {
                activeFilters.remove(.seenLast7Days)
            }
            activeFilters.insert(filter)
        }
    }
}
