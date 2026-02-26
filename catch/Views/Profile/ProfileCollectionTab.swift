import SwiftUI
import SwiftData

struct ProfileCollectionTab: View {
    @Query(sort: \Cat.name) private var cats: [Cat]
    @Query private var encounters: [Encounter]

    @Binding var selectedTab: Int
    @State private var searchText = ""
    @State private var sortOption: CatSortOption = .name

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

    private var filteredCats: [Cat] {
        let filtered: [Cat]
        if searchText.isEmpty {
            filtered = cats
        } else {
            filtered = cats.filter {
                $0.displayName.localizedCaseInsensitiveContains(searchText)
                || $0.location.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        switch sortOption {
        case .name:
            return filtered.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
        case .encounters:
            return filtered.sorted { encounterCount(for: $0) > encounterCount(for: $1) }
        case .recent:
            let stats = encounterStatsByCat
            return filtered.sorted { (stats[$0.persistentModelID]?.lastDate ?? .distantPast) > (stats[$1.persistentModelID]?.lastDate ?? .distantPast) }
        }
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
            } else if filteredCats.isEmpty {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: CatchStrings.Collection.searchEmptyTitle,
                    subtitle: CatchStrings.Collection.searchEmptySubtitle(searchText)
                )
            } else {
                LazyVGrid(columns: columns, spacing: CatchSpacing.space16) {
                    ForEach(filteredCats) { cat in
                        NavigationLink(value: cat) {
                            CatCardView(data: CatDisplayData(local: cat, encounterCount: encounterCount(for: cat)))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.top, CatchSpacing.space8)
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
                        ForEach(CatSortOption.allCases) { option in
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
}
