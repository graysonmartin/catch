import SwiftUI
import CatchCore

private enum DetailLayout {
    static let catPhotoSize: CGFloat = 40
    static let pillFontSize: CGFloat = 9
static let pillActiveOpacity: Double = 0.15
    static let pillInactiveOpacity: Double = 0.1
    static let heartIconSize: CGFloat = 10
    static let carouselHeight: CGFloat = 260
}

struct EncounterDetailSheet: View {
    let data: EncounterDetailData
    var isOwnEncounter: Bool = true

    @Environment(SupabaseSocialInteractionService.self) private var socialService: SupabaseSocialInteractionService?
    @Environment(SupabaseAuthService.self) private var authService
    @Environment(ToastManager.self) private var toastManager
    @Environment(\.dismiss) private var dismiss

    @State private var comments: [EncounterComment] = []
    @State private var newCommentText = ""
    @State private var isLoading = false
    @State private var showLikedBySheet = false
    @State private var showReportSheet = false

    private var currentUserID: String? {
        authService.authState.user?.id
    }

    private var encounterRecordName: String { data.id }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                scrollContent
                Divider()
                CommentInputBar(text: $newCommentText) {
                    Task { await submitComment() }
                }
            }
            .background(CatchTheme.background)
            .navigationTitle(CatchStrings.Diary.encounterDetail)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: CatchSpacing.space12) {
                        #if DEBUG
                        overflowMenu
                        #else
                        if !isOwnEncounter {
                            overflowMenu
                        }
                        #endif
                        Button(CatchStrings.Common.done) { dismiss() }
                    }
                }
            }
            .sheet(isPresented: $showReportSheet) {
                ReportEncounterView(encounterRecordName: encounterRecordName)
            }
            .navigationDestination(for: RemoteProfileRoute.self) { route in
                RemoteProfileContent(
                    userID: route.userID,
                    initialDisplayName: route.displayName
                )
            }
            .task { await loadComments() }
            .simultaneousGesture(
                DragGesture(minimumDistance: 60)
                    .onEnded { value in
                        let horizontal = value.translation.width
                        if horizontal > 100, horizontal > abs(value.translation.height) {
                            dismiss()
                        }
                    }
            )
        }
    }

    // MARK: - Overflow Menu

    private var overflowMenu: some View {
        Menu {
            Button(role: .destructive) {
                showReportSheet = true
            } label: {
                Label(CatchStrings.Report.reportPost, systemImage: "flag")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .foregroundStyle(CatchTheme.textSecondary)
        }
        .accessibilityLabel(CatchStrings.Accessibility.moreOptions)
    }

    // MARK: - Scroll Content

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if !data.photos.isEmpty || !data.photoUrls.isEmpty {
                    PhotoCarouselView(photos: data.photos, photoUrls: data.photoUrls, height: DetailLayout.carouselHeight, isTappable: true)
                        .padding(.bottom, CatchSpacing.space12)
                }

                catHeader
                    .padding(.horizontal)
                    .padding(.bottom, CatchSpacing.space8)

                if !data.breed.isEmpty {
                    breedRow
                        .padding(.horizontal)
                        .padding(.bottom, CatchSpacing.space8)
                }

                if !data.locationName.isEmpty {
                    locationRow
                        .padding(.horizontal)
                        .padding(.bottom, CatchSpacing.space8)
                }

                if data.posterDisplayName != nil {
                    posterRow
                        .padding(.horizontal)
                        .padding(.bottom, CatchSpacing.space8)
                }

                if !data.notes.isEmpty {
                    notesRow
                        .padding(.horizontal)
                        .padding(.bottom, CatchSpacing.space8)
                }

                Divider()
                    .padding(.vertical, CatchSpacing.space8)

                interactionRow
                    .padding(.horizontal)
                    .padding(.bottom, CatchSpacing.space8)

                Divider()
                    .padding(.bottom, CatchSpacing.space8)

                commentSection
                    .padding(.horizontal)
            }
            .padding(.vertical, CatchSpacing.space12)
        }
    }

    // MARK: - Cat Header

    private var catHeader: some View {
        HStack(spacing: CatchSpacing.space10) {
            CatPhotoView(photoData: data.catPhotoData, photoUrl: data.catPhotoUrl, size: DetailLayout.catPhotoSize)

            VStack(alignment: .leading, spacing: CatchSpacing.space2) {
                HStack(spacing: CatchSpacing.space4) {
                    Text(data.catName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(data.isUnnamed ? CatchTheme.textSecondary : CatchTheme.textPrimary)

                    encounterPill

                    if data.isOwned {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(CatchTheme.primary)
                            .font(.system(size: DetailLayout.heartIconSize))
                    }
                }

                Text(DateFormatting.encounterDateTime(data.date))
                    .font(.caption)
                    .foregroundStyle(CatchTheme.textSecondary)
            }

            Spacer()
        }
    }

    private var encounterPill: some View {
        Text(data.isFirstEncounter ? CatchStrings.Feed.pillNew : CatchStrings.Feed.pillRepeat)
            .font(.system(size: DetailLayout.pillFontSize, weight: .bold))
            .foregroundStyle(data.isFirstEncounter ? CatchTheme.primary : CatchTheme.textSecondary)
            .padding(.horizontal, CatchSpacing.space6)
            .padding(.vertical, CatchSpacing.space2)
            .background(
                RoundedRectangle(cornerRadius: CatchSpacing.space4)
                    .fill(data.isFirstEncounter
                        ? CatchTheme.primary.opacity(DetailLayout.pillActiveOpacity)
                        : CatchTheme.textSecondary.opacity(DetailLayout.pillInactiveOpacity))
            )
    }

    // MARK: - Breed, Location & Notes

    private var breedRow: some View {
        HStack(spacing: CatchSpacing.space6) {
            Image(systemName: "pawprint.fill")
                .frame(width: 16, alignment: .center)
            Text(data.breed)
        }
        .font(.subheadline)
        .foregroundStyle(CatchTheme.textSecondary)
    }

    private var locationRow: some View {
        HStack(spacing: CatchSpacing.space6) {
            Image(systemName: "mappin.circle.fill")
                .frame(width: 16, alignment: .center)
            Text(data.locationName)
        }
        .font(.subheadline)
        .foregroundStyle(CatchTheme.textSecondary)
    }

    private var notesRow: some View {
        Text(data.notes)
            .font(.subheadline)
            .foregroundStyle(CatchTheme.textPrimary)
    }

    // MARK: - Poster

    @ViewBuilder
    private var posterRow: some View {
        if let displayName = data.posterDisplayName, let userID = data.posterUserID {
            NavigationLink(value: RemoteProfileRoute(userID: userID, displayName: displayName)) {
                HStack(spacing: CatchSpacing.space8) {
                    posterAvatarView

                    if let username = data.posterUsername, !username.isEmpty {
                        Text("@\(username)")
                            .font(.subheadline)
                            .foregroundStyle(CatchTheme.textSecondary)
                    } else {
                        Text(displayName)
                            .font(.subheadline)
                            .foregroundStyle(CatchTheme.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(CatchTheme.textSecondary.opacity(0.5))
                }
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var posterAvatarView: some View {
        if let avatarUrl = data.posterAvatarURL, !avatarUrl.isEmpty {
            RemoteImageView(urlString: avatarUrl) {
                posterAvatarPlaceholder
            }
            .frame(width: 28, height: 28)
            .clipShape(Circle())
        } else {
            posterAvatarPlaceholder
        }
    }

    private var posterAvatarPlaceholder: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 28, height: 28)
            .foregroundStyle(CatchTheme.secondary)
    }

    // MARK: - Interaction

    private var interactionRow: some View {
        HStack(spacing: CatchSpacing.space16) {
            likeSection
            viewLikesButton
            commentCountLabel
            Spacer()
        }
        .sheet(isPresented: $showLikedBySheet) {
            LikedByListView(encounterRecordName: encounterRecordName)
        }
    }

    private var likeSection: some View {
        HStack(spacing: CatchSpacing.space4) {
            Button {
                guard let socialService else { return }
                Task {
                    do {
                        try await socialService.toggleLike(encounterRecordName: encounterRecordName)
                    } catch is RateLimitError {
                        toastManager.showError(CatchStrings.Toast.rateLimitedLike)
                    } catch {
                        toastManager.showError(CatchStrings.Toast.likeFailed)
                    }
                }
            } label: {
                Image(systemName: isLikedByCurrentUser ? "heart.fill" : "heart")
                    .foregroundStyle(isLikedByCurrentUser ? CatchTheme.primary : CatchTheme.textSecondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)

            if totalLikeCount > 0 {
                Text("\(totalLikeCount)")
                    .font(.subheadline)
                    .foregroundStyle(CatchTheme.textSecondary)
            }
        }
    }

    @ViewBuilder
    private var viewLikesButton: some View {
        if totalLikeCount > 0 {
            Button {
                showLikedBySheet = true
            } label: {
                Text(CatchStrings.Interaction.viewLikes)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(CatchTheme.primary)
            }
            .buttonStyle(.plain)
        }
    }

    private var commentCountLabel: some View {
        HStack(spacing: CatchSpacing.space4) {
            Image(systemName: "bubble.right")
                .foregroundStyle(CatchTheme.textSecondary)
            if totalCommentCount > 0 {
                Text("\(totalCommentCount)")
                    .font(.subheadline)
                    .foregroundStyle(CatchTheme.textSecondary)
            }
        }
    }

    private var isLikedByCurrentUser: Bool {
        socialService?.isLiked(encounterRecordName) ?? false
    }

    private var totalLikeCount: Int {
        socialService?.likeCount(for: encounterRecordName) ?? 0
    }

    private var totalCommentCount: Int {
        socialService?.commentCount(for: encounterRecordName) ?? 0
    }

    // MARK: - Comments

    @ViewBuilder
    private var commentSection: some View {
        if isLoading && comments.isEmpty {
            PawLoadingView(size: .inline)
                .padding(.vertical, CatchSpacing.space24)
        } else if comments.isEmpty {
            EmptyStateView(
                icon: "bubble.right",
                title: CatchStrings.Interaction.noCommentsTitle,
                subtitle: CatchStrings.Interaction.noCommentsSubtitle
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, CatchSpacing.space32)
        } else {
            LazyVStack(alignment: .leading, spacing: CatchSpacing.space12) {
                ForEach(comments) { comment in
                    CommentRowView(
                        comment: comment,
                        currentUserID: currentUserID,
                        onDelete: { deleteComment(comment) }
                    )
                }
            }
        }
    }

    // MARK: - Actions

    private func loadComments() async {
        guard let socialService else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let (fetched, _) = try await socialService.fetchComments(
                encounterRecordName: encounterRecordName,
                cursor: nil
            )
            comments = fetched
        } catch {
            // Comments fail silently — not critical
        }
    }

    private func submitComment() async {
        guard let socialService else { return }
        let text = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        newCommentText = ""

        let pendingComment = EncounterComment.pending(
            encounterRecordName: encounterRecordName,
            userID: currentUserID ?? "",
            displayName: CatchStrings.Social.you,
            text: text
        )

        withAnimation(.easeInOut(duration: 0.2)) {
            comments.insert(pendingComment, at: 0)
        }

        do {
            let confirmed = try await socialService.addComment(
                encounterRecordName: encounterRecordName,
                text: text
            )
            if let index = comments.firstIndex(where: { $0.id == pendingComment.id }) {
                comments[index] = confirmed
            }
        } catch is RateLimitError {
            withAnimation(.easeInOut(duration: 0.2)) {
                comments.removeAll { $0.id == pendingComment.id }
            }
            newCommentText = text
            toastManager.showError(CatchStrings.Toast.rateLimitedComment)
        } catch {
            withAnimation(.easeInOut(duration: 0.2)) {
                comments.removeAll { $0.id == pendingComment.id }
            }
            newCommentText = text
            toastManager.showError(CatchStrings.Toast.commentFailed)
        }
    }

    private func deleteComment(_ comment: EncounterComment) {
        guard let socialService else { return }
        let removedComment = comment
        comments.removeAll { $0.id == comment.id }
        Task {
            do {
                try await socialService.deleteComment(
                    recordName: removedComment.id,
                    encounterRecordName: encounterRecordName
                )
            } catch is RateLimitError {
                comments.insert(removedComment, at: 0)
                toastManager.showError(CatchStrings.Toast.rateLimitedDeleteComment)
            } catch {
                comments.insert(removedComment, at: 0)
                toastManager.showError(CatchStrings.Toast.commentDeleteFailed)
            }
        }
    }
}
