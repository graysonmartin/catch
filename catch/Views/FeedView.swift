import SwiftUI
import SwiftData

enum FeedSortOption: String, CaseIterable, Identifiable {
    case newest = "newest first"
    case oldest = "oldest first"

    var id: String { rawValue }
}

struct FeedView: View {
    @Query(sort: \Encounter.date, order: .reverse) private var encounters: [Encounter]
    @Query private var cats: [Cat]
    @Binding var scrollToTop: Bool
    @State private var searchText = ""
    @State private var sortOption: FeedSortOption = .newest

    private var filteredEncounters: [Encounter] {
        let filtered: [Encounter]
        if searchText.isEmpty {
            filtered = encounters
        } else {
            filtered = encounters.filter { encounter in
                let matchesCatName = encounter.cat?.name.localizedCaseInsensitiveContains(searchText) ?? false
                let matchesNotes = encounter.notes.localizedCaseInsensitiveContains(searchText)
                let matchesLocation = encounter.location.name.localizedCaseInsensitiveContains(searchText)
                return matchesCatName || matchesNotes || matchesLocation
            }
        }

        switch sortOption {
        case .newest:
            return filtered.sorted { $0.date > $1.date }
        case .oldest:
            return filtered.sorted { $0.date < $1.date }
        }
    }

    var body: some View {
        let _ = cats // Observe cat changes so feed items refresh after edits
        NavigationStack {
            Group {
                if encounters.isEmpty {
                    EmptyStateView(
                        icon: "pawprint.circle",
                        title: "No Encounters Yet",
                        subtitle: "Log your first cat encounter using the Log tab."
                    )
                } else if filteredEncounters.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "nothing here",
                        subtitle: "no encounters matching \"\(searchText)\""
                    )
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredEncounters) { encounter in
                                    if let cat = encounter.cat {
                                        NavigationLink(value: cat) {
                                            FeedItemView(encounter: encounter)
                                        }
                                        .buttonStyle(.plain)
                                    } else {
                                        FeedItemView(encounter: encounter)
                                    }
                                }
                            }
                            .padding()
                            .id("feedTop")
                        }
                        .onChange(of: scrollToTop) {
                            if scrollToTop {
                                withAnimation {
                                    proxy.scrollTo("feedTop", anchor: .top)
                                }
                                scrollToTop = false
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(CatchTheme.background)
            .navigationTitle("Feed")
            .searchable(text: $searchText, prompt: "search encounters")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("sort by", selection: $sortOption) {
                            ForEach(FeedSortOption.allCases) { option in
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
