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
    @Environment(CKSocialFeedService.self) private var socialFeedService: CKSocialFeedService?
    @Query(sort: \Encounter.date, order: .reverse) private var encounters: [Encounter]
    @Query private var cats: [Cat]
    @Binding var scrollToTop: Bool
    @Binding var selectedTab: Int
    @State private var searchText = ""
    @State private var sortOption: FeedSortOption = .newest
    @State private var encounterToDelete: Encounter?

    private var unifiedFeedItems: [FeedItem] {
        let localItems = encounters.map { FeedItem.local($0) }
        let remoteItems = socialFeedService?.remoteEncounters ?? []
        var all = localItems + remoteItems

        if !searchText.isEmpty {
            all = all.filter { item in
                switch item {
                case .local(let encounter):
                    let matchesCatName = encounter.cat?.displayName.localizedCaseInsensitiveContains(searchText) ?? false
                    let matchesNotes = encounter.notes.localizedCaseInsensitiveContains(searchText)
                    let matchesLocation = encounter.location.name.localizedCaseInsensitiveContains(searchText)
                    return matchesCatName || matchesNotes || matchesLocation
                case .remote(let encounter, let cat, let owner):
                    let matchesCatName = cat?.displayName.localizedCaseInsensitiveContains(searchText) ?? false
                    let matchesNotes = encounter.notes.localizedCaseInsensitiveContains(searchText)
                    let matchesLocation = encounter.locationName.localizedCaseInsensitiveContains(searchText)
                    let matchesOwner = owner.displayName.localizedCaseInsensitiveContains(searchText)
                    return matchesCatName || matchesNotes || matchesLocation || matchesOwner
                }
            }
        }

        switch sortOption {
        case .newest:
            return all.sorted { $0.date > $1.date }
        case .oldest:
            return all.sorted { $0.date < $1.date }
        }
    }

    var body: some View {
        let _ = cats
        NavigationStack {
            Group {
                if encounters.isEmpty && (socialFeedService?.remoteEncounters.isEmpty ?? true) {
                    EmptyStateView(
                        icon: "pawprint.circle",
                        title: CatchStrings.Feed.emptyTitle,
                        subtitle: CatchStrings.Feed.emptySubtitle,
                        actionLabel: CatchStrings.Feed.emptyAction,
                        action: { selectedTab = 1 }
                    )
                } else if unifiedFeedItems.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: CatchStrings.Feed.searchEmptyTitle,
                        subtitle: CatchStrings.Feed.searchEmptySubtitle(searchText)
                    )
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: CatchSpacing.space16) {
                                ForEach(unifiedFeedItems) { item in
                                    feedItemView(for: item)
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
            .refreshable {
                await socialFeedService?.refresh()
            }
            .task {
                await loadInteractionData()
                await socialFeedService?.refresh()
            }
        }
    }

    // MARK: - Feed Item Routing

    @ViewBuilder
    private func feedItemView(for item: FeedItem) -> some View {
        switch item {
        case .local(let encounter):
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
        case .remote(let encounter, let cat, let owner):
            SocialFeedItemView(encounter: encounter, cat: cat, owner: owner)
        }
    }

    // MARK: - Data Loading

    private func loadInteractionData() async {
        guard let socialService else { return }
        let localRecordNames = encounters.compactMap(\.cloudKitRecordName)
        let remoteRecordNames = socialFeedService?.remoteEncounters.compactMap(\.encounterRecordName) ?? []
        let allRecordNames = localRecordNames + remoteRecordNames
        guard !allRecordNames.isEmpty else { return }
        try? await socialService.loadInteractionData(for: allRecordNames)
    }
}
