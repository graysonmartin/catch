import SwiftUI
import CatchCore

struct RemoteCollectionTab: View {
    let cats: [CloudCat]
    let encounters: [CloudEncounter]
    let ownerName: String

    @State private var sortOption: CollectionSortOption = .mostRecent
    @State private var activeFilters: Set<CollectionFilter> = []
    @State private var searchText = ""

    private let service: CollectionSortFilterService = DefaultCollectionSortFilterService()

    private let columns = [
        GridItem(.flexible(), spacing: CatchSpacing.space16),
        GridItem(.flexible(), spacing: CatchSpacing.space16)
    ]

    private func encounterCount(for cat: CloudCat) -> Int {
        encounters.filter { $0.catRecordName == cat.recordName }.count
    }

    private func lastEncounterDate(for cat: CloudCat) -> Date? {
        encounters
            .filter { $0.catRecordName == cat.recordName }
            .map(\.date)
            .max()
    }

    private var processedCats: [CloudCat] {
        let searched: [CloudCat]
        if searchText.isEmpty {
            searched = cats
        } else {
            searched = cats.filter {
                $0.displayName.localizedCaseInsensitiveContains(searchText)
                || $0.locationName.localizedCaseInsensitiveContains(searchText)
            }
        }

        let items = searched.map { cat in
            CollectionCatItem(
                id: cat.recordName,
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
            uniqueKeysWithValues: searched.map { ($0.recordName, $0) }
        )
        return orderedIDs.compactMap { catsByID[$0] }
    }

    var body: some View {
        ScrollView {
            if cats.isEmpty {
                EmptyStateView(
                    icon: "square.grid.2x2",
                    title: CatchStrings.Social.noCatsYetTitle,
                    subtitle: CatchStrings.Social.noCatsYetSubtitle
                )
                .padding(.top, CatchSpacing.space32)
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
                            ForEach(processedCats, id: \.recordName) { cat in
                                NavigationLink {
                                    RemoteCatProfileView(
                                        cat: cat,
                                        encounters: encounters,
                                        ownerName: ownerName
                                    )
                                } label: {
                                    CatCardView(
                                        data: CatDisplayData(
                                            remote: cat,
                                            encounterCount: encounterCount(for: cat)
                                        )
                                    )
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
