import SwiftUI
import CatchCore

/// Pushable encounter detail view that loads data from an encounter ID.
/// Unlike `EncounterDetailSheet`, this omits its own `NavigationStack`
/// so it can be pushed onto an existing navigation stack.
struct EncounterDetailLoadingView: View {
    let encounterID: String

    @Environment(EncounterDataService.self) private var encounterDataService
    @Environment(CatDataService.self) private var catDataService
    @Environment(SupabaseSocialInteractionService.self) private var socialService: SupabaseSocialInteractionService?
    @Environment(SupabaseAuthService.self) private var authService
    @Environment(ToastManager.self) private var toastManager

    @State private var data: EncounterDetailData?
    @State private var isLoading = true
    @State private var loadFailed = false
    @State private var comments: [EncounterComment] = []
    @State private var newCommentText = ""
    @State private var isLoadingComments = false
    @State private var showLikedBySheet = false
    @State private var showReportSheet = false

    private var currentUserID: String? { authService.authState.user?.id }

    var body: some View {
        Group {
            if let data {
                encounterContent(data)
            } else if loadFailed {
                EmptyStateView(
                    icon: "exclamationmark.triangle",
                    title: CatchStrings.Notifications.encounterLoadFailed,
                    subtitle: CatchStrings.Notifications.encounterLoadFailedSubtitle
                )
            } else {
                PawLoadingView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CatchTheme.background)
        .navigationTitle(CatchStrings.Diary.encounterDetail)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if data != nil, !(data?.isOwned ?? true) {
                    overflowMenu
                }
            }
        }
        .sheet(isPresented: $showReportSheet) {
            ReportEncounterView(encounterRecordName: encounterID)
        }
        .sheet(isPresented: $showLikedBySheet) {
            LikedByListView(encounterRecordName: encounterID)
        }
        .task { await loadEncounter() }
    }

    // MARK: - Content

    @ViewBuilder
    private func encounterContent(_ data: EncounterDetailData) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if !data.photos.isEmpty || !data.photoUrls.isEmpty {
                        PhotoCarouselView(
                            photos: data.photos,
                            photoUrls: data.photoUrls,
                            height: 260,
                            isTappable: true
                        )
                        .padding(.bottom, CatchSpacing.space12)
                    }

                    catHeader(data)
                        .padding(.horizontal)
                        .padding(.bottom, CatchSpacing.space8)

                    if !data.breed.isEmpty {
                        metadataRow(icon: "pawprint.fill", text: data.breed)
                            .padding(.horizontal)
                            .padding(.bottom, CatchSpacing.space8)
                    }

                    if !data.locationName.isEmpty {
                        metadataRow(icon: "mappin.circle.fill", text: data.locationName)
                            .padding(.horizontal)
                            .padding(.bottom, CatchSpacing.space8)
                    }

                    if !data.notes.isEmpty {
                        Text(data.notes)
                            .font(.subheadline)
                            .foregroundStyle(CatchTheme.textPrimary)
                            .padding(.horizontal)
                            .padding(.bottom, CatchSpacing.space8)
                    }

                    Divider().padding(.vertical, CatchSpacing.space8)

                    interactionRow
                        .padding(.horizontal)
                        .padding(.bottom, CatchSpacing.space8)

                    Divider().padding(.bottom, CatchSpacing.space8)

                    commentSection
                        .padding(.horizontal)
                }
                .padding(.vertical, CatchSpacing.space12)
            }

            Divider()
            CommentInputBar(text: $newCommentText) {
                Task { await submitComment() }
            }
        }
        .task { await loadComments() }
    }

    // MARK: - Subviews

    private func catHeader(_ data: EncounterDetailData) -> some View {
        HStack(spacing: CatchSpacing.space10) {
            CatPhotoView(photoData: data.catPhotoData, photoUrl: data.catPhotoUrl, size: 40)

            VStack(alignment: .leading, spacing: CatchSpacing.space2) {
                HStack(spacing: CatchSpacing.space4) {
                    Text(data.catName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(data.isUnnamed ? CatchTheme.textSecondary : CatchTheme.textPrimary)

                    Text(data.isFirstEncounter ? CatchStrings.Feed.pillNew : CatchStrings.Feed.pillRepeat)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(data.isFirstEncounter ? CatchTheme.primary : CatchTheme.textSecondary)
                        .padding(.horizontal, CatchSpacing.space6)
                        .padding(.vertical, CatchSpacing.space2)
                        .background(
                            RoundedRectangle(cornerRadius: CatchSpacing.space4)
                                .fill(data.isFirstEncounter
                                    ? CatchTheme.primary.opacity(0.15)
                                    : CatchTheme.textSecondary.opacity(0.1))
                        )

                    if data.isOwned {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(CatchTheme.primary)
                            .font(.system(size: 10))
                    }
                }

                Text(data.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(CatchTheme.textSecondary)
            }

            Spacer()
        }
    }

    private func metadataRow(icon: String, text: String) -> some View {
        HStack(spacing: CatchSpacing.space6) {
            Image(systemName: icon)
                .frame(width: 16, alignment: .center)
            Text(text)
        }
        .font(.subheadline)
        .foregroundStyle(CatchTheme.textSecondary)
    }

    // MARK: - Interaction

    private var interactionRow: some View {
        HStack(spacing: CatchSpacing.space16) {
            likeButton
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
            HStack(spacing: CatchSpacing.space4) {
                Image(systemName: "bubble.right")
                    .foregroundStyle(CatchTheme.textSecondary)
                if totalCommentCount > 0 {
                    Text("\(totalCommentCount)")
                        .font(.subheadline)
                        .foregroundStyle(CatchTheme.textSecondary)
                }
            }
            Spacer()
        }
    }

    private var likeButton: some View {
        HStack(spacing: CatchSpacing.space4) {
            Button {
                guard let socialService else { return }
                Task {
                    do {
                        try await socialService.toggleLike(encounterRecordName: encounterID)
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

    private var isLikedByCurrentUser: Bool {
        socialService?.isLiked(encounterID) ?? false
    }

    private var totalLikeCount: Int {
        socialService?.likeCount(for: encounterID) ?? 0
    }

    private var totalCommentCount: Int {
        socialService?.commentCount(for: encounterID) ?? 0
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

    // MARK: - Comments

    @ViewBuilder
    private var commentSection: some View {
        if isLoadingComments && comments.isEmpty {
            PawLoadingView(size: .inline)
                .padding(.vertical, CatchSpacing.space24)
        } else if comments.isEmpty {
            EmptyStateView(
                icon: "bubble.right",
                title: CatchStrings.Interaction.noCommentsTitle,
                subtitle: CatchStrings.Interaction.noCommentsSubtitle
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    private func loadEncounter() async {
        do {
            guard let encounter = try await encounterDataService.fetchEncounter(id: encounterID) else {
                loadFailed = true
                return
            }
            let cat = try? await catDataService.fetchCat(id: encounter.catID)
            data = EncounterDetailData(supabase: encounter, cat: cat)
        } catch {
            loadFailed = true
        }
    }

    private func loadComments() async {
        guard let socialService else { return }
        isLoadingComments = true
        defer { isLoadingComments = false }
        do {
            let (fetched, _) = try await socialService.fetchComments(
                encounterRecordName: encounterID,
                cursor: nil
            )
            comments = fetched
        } catch {
            // Comments fail silently
        }
    }

    private func submitComment() async {
        guard let socialService else { return }
        let text = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        newCommentText = ""

        let pendingComment = EncounterComment.pending(
            encounterRecordName: encounterID,
            userID: currentUserID ?? "",
            displayName: CatchStrings.Social.you,
            text: text
        )

        withAnimation(.easeInOut(duration: 0.2)) {
            comments.insert(pendingComment, at: 0)
        }

        do {
            let confirmed = try await socialService.addComment(
                encounterRecordName: encounterID,
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
                    encounterRecordName: encounterID
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
