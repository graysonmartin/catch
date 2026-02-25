import SwiftUI
import SwiftData

struct BreedLogView: View {
    @Query(sort: \Cat.name) private var cats: [Cat]
    @State private var sortOption: BreedLogSortOption = .rarity
    @State private var selectedEntry: BreedLogEntry?

    private let service: BreedLogService
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    init(service: BreedLogService = DefaultBreedLogService()) {
        self.service = service
    }

    private var breedLog: [BreedLogEntry] {
        let log = service.buildBreedLog(from: cats)
        return sorted(log)
    }

    private var discoveredCount: Int {
        breedLog.filter(\.isDiscovered).count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                BreedLogProgressView(
                    discoveredCount: discoveredCount,
                    totalCount: BreedCatalog.count
                )

                LazyVGrid(columns: columns, spacing: 8) {
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
        .navigationTitle("breed log")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("sort by", selection: $sortOption) {
                        ForEach(BreedLogSortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
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
                cats: service.catsForBreed(entry.id, from: cats)
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
