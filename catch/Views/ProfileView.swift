import SwiftUI
import SwiftData
import AuthenticationServices

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppleAuthService.self) var authService
    @Environment(CKFollowService.self) var followService
    @Query private var profiles: [UserProfile]
    @Query(sort: \Cat.name) var cats: [Cat]
    @Query var encounters: [Encounter]

    @Binding var selectedTab: Int
    @State private var isShowingEditSheet = false
    @State private var searchText = ""
    @State private var sortOption: CatSortOption = .name

    var cloudKitService: CloudKitService = CKCloudKitService()

    private var profile: UserProfile? { profiles.first }

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    private var filteredCats: [Cat] {
        let filtered: [Cat]
        if searchText.isEmpty {
            filtered = cats
        } else {
            filtered = cats.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.location.name.localizedCaseInsensitiveContains(searchText)
            }
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
            ScrollView {
                VStack(spacing: 24) {
                    if let profile {
                        profileHeader(profile)
                    } else {
                        setupBanner
                        breedLogCard
                    }

                    collectionSection

                    if let profile {
                        authSection(profile)
                        joinDateSection(profile)
                    }
                }
                .padding(.vertical, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(CatchTheme.background)
            .navigationTitle(CatchStrings.Profile.profileTitle)
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: CatchStrings.Collection.searchPrompt)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
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
                    if profile != nil {
                        Button {
                            isShowingEditSheet = true
                        } label: {
                            Image(systemName: "pencil")
                                .foregroundStyle(CatchTheme.primary)
                        }
                    }
                }
            }
            .navigationDestination(for: Cat.self) { cat in
                CatProfileView(cat: cat)
            }
            .sheet(item: Binding(
                get: { isShowingEditSheet ? profile : nil },
                set: { _ in isShowingEditSheet = false }
            )) { profile in
                EditProfileView(profile: profile) { updatedProfile in
                    syncProfileToCloudKit(updatedProfile)
                }
            }
        }
    }

    // MARK: - Collection Section

    @ViewBuilder
    private var collectionSection: some View {
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
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(filteredCats) { cat in
                    NavigationLink(value: cat) {
                        CatCardView(cat: cat)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Setup Banner

    private var setupBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.title2)
                .foregroundStyle(CatchTheme.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text(CatchStrings.Profile.emptyTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CatchTheme.textPrimary)
                Text(CatchStrings.Profile.emptySubtitle)
                    .font(.caption)
                    .foregroundStyle(CatchTheme.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            Button {
                createProfile()
            } label: {
                Text(CatchStrings.Profile.setUpProfile)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(CatchTheme.primary)
                    .clipShape(Capsule())
            }
        }
        .padding(16)
        .background(CatchTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadius))
        .shadow(
            color: .black.opacity(CatchTheme.cardShadowOpacity),
            radius: CatchTheme.cardShadowRadius,
            y: CatchTheme.cardShadowY
        )
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private func createProfile() {
        let profile = UserProfile()
        modelContext.insert(profile)
        isShowingEditSheet = true
    }
}
