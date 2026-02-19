import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var cats: [Cat]
    @Query private var encounters: [Encounter]
    @Query private var careEntries: [CareEntry]

    @State private var isShowingEditSheet = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            Group {
                if let profile {
                    profileContent(profile)
                } else {
                    emptyState
                }
            }
            .background(CatchTheme.background)
            .navigationTitle("profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if profile != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isShowingEditSheet = true
                        } label: {
                            Image(systemName: "pencil")
                        }
                    }
                }
            }
            .sheet(item: Binding(
                get: { isShowingEditSheet ? profile : nil },
                set: { _ in isShowingEditSheet = false }
            )) { profile in
                EditProfileView(profile: profile)
            }
        }
    }

    // MARK: - Profile Content

    private func profileContent(_ profile: UserProfile) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                avatarSection(profile)
                infoSection(profile)
                statsSection
                joinDateSection(profile)
            }
            .padding(.vertical, 24)
        }
    }

    private func avatarSection(_ profile: UserProfile) -> some View {
        Group {
            if let data = profile.avatarData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundStyle(CatchTheme.secondary)
            }
        }
    }

    private func infoSection(_ profile: UserProfile) -> some View {
        VStack(spacing: 6) {
            Text(profile.displayName.isEmpty ? "mysterious stranger" : profile.displayName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(CatchTheme.textPrimary)

            Text(profile.bio.isEmpty ? "too cool for a bio" : profile.bio)
                .font(.subheadline)
                .foregroundStyle(CatchTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var statsSection: some View {
        HStack(spacing: 12) {
            statCard(count: cats.count, label: "cats", icon: "cat.fill")
            statCard(count: encounters.count, label: "encounters", icon: "pawprint.fill")
            statCard(count: totalCareDays, label: "care days", icon: "heart.fill")
        }
        .padding(.horizontal, 20)
    }

    private func statCard(count: Int, label: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(CatchTheme.primary)

            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(CatchTheme.textPrimary)

            Text(label)
                .font(.caption)
                .foregroundStyle(CatchTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(CatchTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadius))
        .shadow(
            color: .black.opacity(CatchTheme.cardShadowOpacity),
            radius: CatchTheme.cardShadowRadius,
            y: CatchTheme.cardShadowY
        )
    }

    private func joinDateSection(_ profile: UserProfile) -> some View {
        Text("lurking since \(profile.createdAt.formatted(.dateTime.month(.wide).year()))")
            .font(.caption)
            .foregroundStyle(CatchTheme.textSecondary)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            EmptyStateView(
                icon: "person.crop.circle.badge.questionmark",
                title: "who even are you",
                subtitle: "set up your profile so the cats know who they're dealing with"
            )
            Button {
                createProfile()
            } label: {
                Text("set up profile")
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(CatchTheme.primary)
                    .clipShape(Capsule())
            }
            Spacer()
        }
    }

    // MARK: - Helpers

    private var totalCareDays: Int {
        careEntries.reduce(0) { total, entry in
            let days = Calendar.current.dateComponents(
                [.day],
                from: entry.startDate,
                to: entry.endDate
            ).day ?? 0
            return total + max(days, 1)
        }
    }

    private func createProfile() {
        let profile = UserProfile()
        modelContext.insert(profile)
        isShowingEditSheet = true
    }
}
