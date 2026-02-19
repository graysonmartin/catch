import SwiftUI
import SwiftData

enum CatSortOption: String, CaseIterable, Identifiable {
    case name = "name"
    case encounters = "most seen"
    case recent = "recently seen"

    var id: String { rawValue }
}

struct CollectionView: View {
    @Query(sort: \Cat.name) private var cats: [Cat]
    @State private var searchText = ""
    @State private var sortOption: CatSortOption = .name

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    private var filteredCats: [Cat] {
        let filtered: [Cat]
        if searchText.isEmpty {
            filtered = cats
        } else {
            filtered = cats.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        switch sortOption {
        case .name:
            return filtered.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .encounters:
            return filtered.sorted { $0.encounters.count > $1.encounters.count }
        case .recent:
            return filtered.sorted { ($0.lastEncounterDate ?? .distantPast) > ($1.lastEncounterDate ?? .distantPast) }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if cats.isEmpty {
                    EmptyStateView(
                        icon: "square.grid.2x2",
                        title: "No Cats Collected",
                        subtitle: "Cats you encounter will appear here."
                    )
                } else if filteredCats.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "no matches",
                        subtitle: "no cats named \"\(searchText)\" in your collection"
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(filteredCats) { cat in
                                NavigationLink(value: cat) {
                                    CatCardView(cat: cat)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(CatchTheme.background)
            .navigationTitle("Collection")
            .searchable(text: $searchText, prompt: "find a cat")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("sort by", selection: $sortOption) {
                            ForEach(CatSortOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundStyle(CatchTheme.primary)
                    }
                }
            }
            .navigationDestination(for: Cat.self) { cat in
                CatProfileView(cat: cat)
            }
        }
    }
}

struct CatCardView: View {
    let cat: Cat

    var body: some View {
        VStack(spacing: 8) {
            CatPhotoView(photoData: cat.photos.first, size: 120)
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(spacing: 4) {
                HStack {
                    Text(cat.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CatchTheme.textPrimary)
                        .lineLimit(1)
                    if cat.isOwned {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                            .foregroundStyle(CatchTheme.primary)
                    }
                }

                Text("spotted \(cat.encounters.count) time\(cat.encounters.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(CatchTheme.textSecondary)
            }
        }
        .padding(12)
        .background(CatchTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}
