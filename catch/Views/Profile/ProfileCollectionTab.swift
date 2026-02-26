import SwiftUI
import SwiftData

struct ProfileCollectionTab: View {
    let cats: [Cat]
    let filteredCats: [Cat]
    let searchText: String
    let encounterCount: (Cat) -> Int
    @Binding var selectedTab: Int

    private let columns = [
        GridItem(.flexible(), spacing: CatchSpacing.space16),
        GridItem(.flexible(), spacing: CatchSpacing.space16)
    ]

    var body: some View {
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
                        CatCardView(data: CatDisplayData(local: cat, encounterCount: encounterCount(cat)))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
}
