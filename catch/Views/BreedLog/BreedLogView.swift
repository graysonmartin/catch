import SwiftUI
import SwiftData

struct BreedLogView: View {
    @Query(sort: \Cat.name) private var queriedCats: [Cat]
    @State private var sortOption: BreedLogSortOption = .rarity
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
        return sorted(log)
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
                Menu {
                    Picker(CatchStrings.Common.sortBy, selection: $sortOption) {
                        ForEach(BreedLogSortOption.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .foregroundStyle(CatchTheme.primary)
                }
            }
        }
        .sheet(item: $selectedEntry) { entry in
            BreedDetailView(
                entry: entry,
                cats: externalEntries != nil ? [] : service.catsForBreed(entry.id, from: queriedCats)
            )
        }
    }

    // MARK: - Sorting

    private func sorted(_ log: [BreedLogEntry]) -> [BreedLogEntry] {
        switch sortOption {
        case .rarity:
            return log.sorted { $0.catalogEntry.rarity > $1.catalogEntry.rarity }
        case .alphabetical:
            return log.sorted {
                $0.catalogEntry.displayName.localizedCaseInsensitiveCompare($1.catalogEntry.displayName) == .orderedAscending
            }
        case .discoveredFirst:
            return log.sorted { lhs, rhs in
                switch (lhs.isDiscovered, rhs.isDiscovered) {
                case (true, false): return true
                case (false, true): return false
                default: return lhs.catalogEntry.displayName < rhs.catalogEntry.displayName
                }
            }
        }
    }
}
