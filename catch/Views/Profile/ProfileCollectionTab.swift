import SwiftUI
import SwiftData
import CatchCore

struct ProfileCollectionTab: View {
    @Query(sort: \Cat.name) private var cats: [Cat]
    @Query private var encounters: [Encounter]

    @Binding var selectedTab: Int
    @State private var searchText = ""
    @State private var sortOption: CollectionSortOption = .mostRecent
    @State private var activeFilters: Set<CollectionFilter> = []

    private let service: CollectionSortFilterService = DefaultCollectionSortFilterService()

    private let columns = [
        GridItem(.flexible(), spacing: CatchSpacing.space16),
        GridItem(.flexible(), spacing: CatchSpacing.space16)
    ]

    private var encounterStatsByCat: [PersistentIdentifier: (count: Int, lastDate: Date)] {
        var stats: [PersistentIdentifier: (count: Int, lastDate: Date)] = [:]
        for encounter in encounters {
            if let catID = encounter.cat?.persistentModelID {
                let existing = stats[catID]
                stats[catID] = (
                    count: (existing?.count ?? 0) + 1,
                    lastDate: max(encounter.date, existing?.lastDate ?? .distantPast)
                )
            }
        }
        return stats
    }

    private func encounterCount(for cat: Cat) -> Int {
        encounterStatsByCat[cat.persistentModelID]?.count ?? 0
    }

    private func lastEncounterDate(for cat: Cat) -> Date? {
        encounterStatsByCat[cat.persistentModelID]?.lastDate
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
                id: cat.persistentModelID.hashValue.description,
                name: cat.displayName,
                isOwned: cat.isOwned,
                createdAt: cat.createdAt,
                encounterCount: encounterCount(for: cat),
                lastEncounterDate: lastEncounterDate(for: cat)
            )
        }

        let sortedItems = service.apply(
            sort: sortOption,
            filters: activeFilters,
            to: items,
            now: Date()
        )

        let orderedIDs = sortedItems.map(\.id)
        let catsByID = Dictionary(
            uniqueKeysWithValues: searched.map { ($0.persistentModelID.hashValue.description, $0) }
        )
        return orderedIDs.compactMap { catsByID[$0] }
    }

    private var hasActiveFilters: Bool {
        !activeFilters.isEmpty
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
        .searchable(text: \$searchText, prompt: CatchStrings.Collection.searchPrompt)\
        .toolbar {\
            ToolbarItem(placement: .topBarTrailing) {\
                Menu {\
                    Picker(CatchStrings.Common.sortBy, selection: \$sortOption) {\
                        ForEach(CollectionSortOption.allCases) { option in\
                            Text(option.displayName).tag(option)\
                        }\
                    }\
                } label: {\
                    Image(systemName: "arrow.up.arrow.down")\
                        .foregroundStyle(CatchTheme.primary)\
                }\
            }\
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker(CatchStrings.Common.sortBy, selection: $sortOption) {
                        ForEach(CollectionSortOption.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .foregroundStyle(CatchTheme.primary)
                }
            }
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
