import SwiftUI
import SwiftData

enum FeedSortOption: String, CaseIterable, Identifiable {
    case newest = "newest first"
    case oldest = "oldest first"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .newest: CatchStrings.Feed.newestFirst
        case .oldest: CatchStrings.Feed.oldestFirst
        }
    }
}

struct FeedView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(CKSocialInteractionService.self) private var socialService: CKSocialInteractionService?
    @Query(sort: \Encounter.date, order: .reverse) private var encounters: [Encounter]
    @Query private var cats: [Cat]
    @Binding var scrollToTop: Bool
    @Binding var selectedTab: Int
    @State private var searchText = ""
    @State private var sortOption: FeedSortOption = .newest
    @State private var encounterToDelete: Encounter?

    private var filteredEncounters: [Encounter] {
        let filtered: [Encounter]
        if searchText.isEmpty {
            filtered = encounters
        } else {
            filtered = encounters.filter { encounter in
                let matchesCatName = encounter.cat?.displayName.localizedCaseInsensitiveContains(searchText) ?? false
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
                        title: CatchStrings.Feed.emptyTitle,
                        subtitle: CatchStrings.Feed.emptySubtitle,
                        actionLabel: CatchStrings.Feed.emptyAction,
                        action: { selectedTab = 1 }
                    )
                } else if filteredEncounters.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: CatchStrings.Feed.searchEmptyTitle,
                        subtitle: CatchStrings.Feed.searchEmptySubtitle(searchText)
                    )
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: CatchSpacing.space16) {
                                ForEach(filteredEncounters) { encounter in
                                    if let cat = encounter.cat {
                                        NavigationLink(value: cat) {
                                            FeedItemView(encounter: encounter)
                                        }
                                        .buttonStyle(.plain)
                                    } else {
                                        FeedItemView(encounter: encounter)
                                            .overlay(alignment: .topTrailing) {
                                                Button {
                                                    encounterToDelete = encounter
                                                } label: {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .font(.title3)
                                                        .foregroundStyle(.white, CatchTheme.textSecondary)
                                                }
                                                .padding(CatchSpacing.space8)
                                            }
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
            .navigationTitle(CatchStrings.Tabs.feed)
            .searchable(text: $searchText, prompt: CatchStrings.Feed.searchPrompt)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker(CatchStrings.Common.sortBy, selection: $sortOption) {
                            ForEach(FeedSortOption.allCases) { option in
                                Text(option.displayName).tag(option)
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
            .alert(CatchStrings.Feed.orphanedAlertTitle, isPresented: Binding(
                get: { encounterToDelete != nil },
                set: { if !$0 { encounterToDelete = nil } }
            )) {
                Button(CatchStrings.Common.delete, role: .destructive) {
                    if let encounter = encounterToDelete {
                        modelContext.delete(encounter)
                        encounterToDelete = nil
                    }
                }
                Button(CatchStrings.Common.cancel, role: .cancel) {
                    encounterToDelete = nil
                }
            } message: {
                Text(CatchStrings.Feed.orphanedAlertMessage)
            }
            .task {
                await loadInteractionData()
            }
        }
    }

    private func loadInteractionData() async {
        guard let socialService else { return }
        let recordNames = encounters.compactMap(\.cloudKitRecordName)
        guard !recordNames.isEmpty else { return }
        try? await socialService.loadInteractionData(for: recordNames)
    }
}
