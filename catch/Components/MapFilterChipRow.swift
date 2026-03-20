import SwiftUI
import CatchCore

struct MapFilterButton: View {
    @Binding var filterState: MapFilterState
    @State private var isExpanded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var springAnimation: Animation? {
        reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.clear
                .contentShape(Rectangle())
                .ignoresSafeArea()
                .allowsHitTesting(isExpanded)
                .onTapGesture {
                    withAnimation(springAnimation) {
                        isExpanded = false
                    }
                }

            VStack(alignment: .trailing, spacing: CatchSpacing.space8) {
                if isExpanded {
                    filterDropdown
                        .transition(reduceMotion ? .opacity : .scale(scale: 0.85, anchor: .bottomTrailing).combined(with: .opacity))
                }

                toggleButton
            }
            .padding(CatchSpacing.space16)
        }
    }

    // MARK: - Toggle Button

    private var toggleButton: some View {
        Button {
            withAnimation(springAnimation) {
                isExpanded.toggle()
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: isExpanded ? "xmark" : "line.3.horizontal.decrease")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isExpanded ? .white : CatchTheme.textPrimary)
                    .frame(width: CatchTheme.minTapTarget, height: CatchTheme.minTapTarget)
                    .background(isExpanded ? CatchTheme.primary : CatchTheme.cardBackground)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.12), radius: 6, y: 3)

                if filterState.hasActiveFilters && !isExpanded {
                    Circle()
                        .fill(CatchTheme.primary)
                        .frame(width: 10, height: 10)
                        .offset(x: -2, y: 2)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            isExpanded
                ? CatchStrings.Accessibility.closeFilters
                : CatchStrings.Accessibility.mapFilterButton
        )
        .accessibilityHint(filterState.hasActiveFilters ? CatchStrings.Accessibility.mapFilterButtonActiveHint : "")
    }

    // MARK: - Dropdown

    private var filterDropdown: some View {
        VStack(alignment: .leading, spacing: CatchSpacing.space12) {
            sectionHeader(CatchStrings.Map.filterWho)
            ownerRow(.myCats, label: CatchStrings.Map.myCats, icon: "person.fill")
            ownerRow(.friendsCats, label: CatchStrings.Map.friendsCats, icon: "person.2.fill")

            Divider()

            sectionHeader(CatchStrings.Map.filterWhen)
            timeRangeRow(.last7Days, label: CatchStrings.Map.last7Days)
            timeRangeRow(.last30Days, label: CatchStrings.Map.last30Days)
            timeRangeRow(.allTime, label: CatchStrings.Map.allTime)

            if filterState.hasActiveFilters {
                Divider()
                resetButton
            }
        }
        .padding(CatchSpacing.space12)
        .frame(width: 200)
        .background(CatchTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadius))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
    }

    // MARK: - Components

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(CatchTheme.textSecondary)
            .textCase(.uppercase)
    }

    private func ownerRow(_ filter: MapOwnerFilter, label: String, icon: String) -> some View {
        let isSelected = filterState.ownerFilters.contains(filter)
        return Button {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                filterState.toggleOwnerFilter(filter)
            }
        } label: {
            HStack(spacing: CatchSpacing.space8) {
                Image(systemName: icon)
                    .font(.caption)
                    .frame(width: 20)
                    .foregroundStyle(isSelected ? CatchTheme.primary : CatchTheme.textSecondary)

                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(CatchTheme.textPrimary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CatchTheme.primary)
                }
            }
            .padding(.vertical, CatchSpacing.space4)
            .frame(minHeight: CatchTheme.minTapTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func timeRangeRow(_ range: MapTimeRange, label: String) -> some View {
        let isSelected = filterState.timeRange == range
        return Button {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                filterState.timeRange = range
            }
        } label: {
            HStack(spacing: CatchSpacing.space8) {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(CatchTheme.textPrimary)
                    .padding(.leading, 28)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CatchTheme.primary)
                }
            }
            .padding(.vertical, CatchSpacing.space4)
            .frame(minHeight: CatchTheme.minTapTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var resetButton: some View {
        Button {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                filterState.reset()
            }
        } label: {
            HStack {
                Spacer()
                Text(CatchStrings.Map.resetFilters)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(CatchTheme.accessibleTextOrange)
                Spacer()
            }
            .padding(.vertical, CatchSpacing.space4)
            .frame(minHeight: CatchTheme.minTapTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
