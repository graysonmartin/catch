import SwiftUI
import CatchCore

struct ProfileCollectionTab: View {
    @Environment(CatDataService.self) private var catDataService

    @Binding var selectedTab: Int
    @State private var searchText = ""
    @State private var sortOption: CollectionSortOption = .lastSeen
    @State private var sortDirection: CollectionSortDirection = CollectionSortOption.lastSeen.defaultDirection
    @State private var activeFilters: Set<CollectionFilter> = []

    private let service: CollectionSortFilterService = DefaultCollectionSortFilterService()

    private let columns = [
        GridItem(.flexible(), spacing: CatchSpacing.space16),
        GridItem(.flexible(), spacing: CatchSpacing.space16)
    ]

    private var cats: [Cat] { catDataService.cats }

    private func encounterCount(for cat: Cat) -> Int {
        cat.encounters.count
    }

    private func lastEncounterDate(for cat: Cat) -> Date? {
        cat.encounters.map(\.date).max()
    }

    private var processedCats: [Cat] {
        let searched: [Cat]
        if searchText.isEmpty {
            searched = cats
        } else {
            searched = cats.filter {
                $0.displayName.localizedCaseInsensitiveContains(searchText)
                || $0.location.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        let items = searched.map { cat in
            CollectionCatItem(
                id: cat.id.uuidString,
                name: cat.displayName,
                isOwned: cat.isOwned,
                createdAt: cat.createdAt,
                encounterCount: encounterCount(for: cat),
                lastEncounterDate: lastEncounterDate(for: cat)
            )
        }

        let sortedItems = service.apply(
            sort: sortOption,
            direction: sortDirection,
            filters: activeFilters,
            to: items,
            now: Date()
        )

        let orderedIDs = sortedItems.map(\.id)
        let catsByID = Dictionary(
            uniqueKeysWithValues: searched.map { ($0.id.uuidString, $0) }
        )
        return orderedIDs.compactMap { catsByID[$0] }
    }

    var body: some View {
        ScrollView {
            if cats.isEmpty {
                EmptyStateView(
                    icon: "square.grid.2x2",
                    title: CatchStrings.Collection.emptyTitle,
                    subtitle: CatchStrings.Collection.emptySubtitle,
                    actionLabel: CatchStrings.Collection.emptyAction,
                    action: { selectedTab = 1 }
                )
            } else {
                VStack(spacing: 0) {
                    CollectionSortFilterBar(
                        activeFilters: $activeFilters
                    )
                    .zIndex(1)

                    if processedCats.isEmpty {
                        filterEmptyState
                    } else {
                        LazyVGrid(columns: columns, spacing: CatchSpacing.space16) {
                            ForEach(processedCats) { cat in
                                NavigationLink {
                                    CatProfileView(cat: cat)
                                } label: {
                                    CatCardView(data: CatDisplayData(local: cat, encounterCount: encounterCount(for: cat)))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, CatchSpacing.space8)
                    }
                }
            }
        }
        .background(CatchTheme.background)
        .navigationTitle(CatchStrings.Profile.collectionTab)
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: CatchStrings.Collection.searchPrompt)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                sortMenu
            }
        }
    }

    // MARK: - Sort Menu

    private var sortMenu: some View {
        Menu {
            ForEach(CollectionSortOption.allCases) { option in
                Button {
                    handleSortTap(option)
                } label: {
                    Label {
                        Text(option.displayName)
                    } icon: {
                        if option == sortOption {
                            Image(systemName: sortDirection.chevronSymbol)
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .foregroundStyle(CatchTheme.primary)
        }
    }

    private func handleSortTap(_ option: CollectionSortOption) {
        if option == sortOption {
            sortDirection = sortDirection.toggled
        } else {
            sortOption = option
            sortDirection = option.defaultDirection
        }
    }

    // MARK: - Filter Empty State

    private var filterEmptyState: some View {
        EmptyStateView(
            icon: "line.3.horizontal.decrease.circle",
            title: searchText.isEmpty
                ? CatchStrings.Collection.filterEmptyTitle
                : CatchStrings.Collection.searchEmptyTitle,
            subtitle: searchText.isEmpty
                ? CatchStrings.Collection.filterEmptySubtitle
                : CatchStrings.Collection.searchEmptySubtitle(searchText)
        )
    }
}
