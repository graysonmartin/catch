import SwiftUI
import SwiftData
import CatchCore

struct BreedLogView: View {
    @Query(sort: \Cat.name) private var queriedCats: [Cat]
    @State private var sortOption: BreedLogSortOption = .rarity
    @State private var sortDirection: BreedLogSortDirection = BreedLogSortOption.rarity.defaultDirection
    @State private var selectedEntry: BreedLogEntry?

    private let externalEntries: [BreedLogEntry]?
    private let service: BreedLogService
    private let columns = [
        GridItem(.flexible(), spacing: CatchSpacing.space8),
        GridItem(.flexible(), spacing: CatchSpacing.space8),
        GridItem(.flexible(), spacing: CatchSpacing.space8)
    ]

    init(entries: [BreedLogEntry]? = nil, service: BreedLogService = DefaultBreedLogService()) {
        self.externalEntries = entries
        self.service = service
    }

    private var breedLog: [BreedLogEntry] {
        let log = externalEntries ?? service.buildBreedLog(from: queriedCats)
        return sortOption.sorted(log, direction: sortDirection)
    }

    private var discoveredCount: Int {
        breedLog.filter(\.isDiscovered).count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: CatchSpacing.space16) {
                BreedLogProgressView(
                    discoveredCount: discoveredCount,
                    totalCount: BreedCatalog.count
                )

                LazyVGrid(columns: columns, spacing: CatchSpacing.space8) {
                    ForEach(breedLog) { entry in
                        BreedLogCardView(entry: entry)
                            .onTapGesture {
                                if entry.isDiscovered {
                                    selectedEntry = entry
                                }
                            }
                    }
                }
            }
            .padding()
        }
        .background(CatchTheme.background)
        .navigationTitle(CatchStrings.BreedLog.title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                sortMenu
            }
        }
        .sheet(item: $selectedEntry) { entry in
            BreedDetailView(
                entry: entry,
                cats: externalEntries != nil ? [] : service.catsForBreed(entry.id, from: queriedCats)
            )
        }
    }

    // MARK: - Sort Menu

    private var sortMenu: some View {
        Menu {
            ForEach(BreedLogSortOption.allCases) { option in
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

    private func handleSortTap(_ option: BreedLogSortOption) {
        if option == sortOption {
            sortDirection = sortDirection.toggled
        } else {
            sortOption = option
            sortDirection = option.defaultDirection
        }
    }
}
