import SwiftUI
import CatchCore

struct CommentThreadView: View {
    let encounterRecordName: String
    var showInteractionBar: Bool = false

    @Environment(CKSocialInteractionService.self) private var socialService: CKSocialInteractionService?
    @Environment(AppleAuthService.self) private var authService
    @Environment(ToastManager.self) private var toastManager

    @State private var comments: [EncounterComment] = []
    @State private var newCommentText = ""
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var cursor: String?

    private var currentUserID: String? {
        authService.authState.user?.userIdentifier
    }

    private var hasMoreComments: Bool {
        cursor != nil
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if showInteractionBar {
                    interactionHeader
                    Divider()
                }
                commentList
                Divider()
                CommentInputBar(text: $newCommentText) {
                    Task { await submitComment() }
                }
            }
            .background(CatchTheme.background)
            .navigationTitle(CatchStrings.Interaction.comments)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(CatchStrings.Common.done) {}
                }
            }
            .task {
                await loadComments()
            }
        }
    }

    // MARK: - Interaction Header

    @ViewBuilder
    private var interactionHeader: some View {
        if showInteractionBar {
            HStack(spacing: CatchSpacing.space16) {
                likeToggleButton
                commentSummaryLabel
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, CatchSpacing.space12)
        }
    }

    private var likeToggleButton: some View {
        Button {
            guard let socialService else { return }
            Task {
                try? await socialService.toggleLike(encounterRecordName: encounterRecordName)
            }
        } label: {
            HStack(spacing: CatchSpacing.space4) {
                Image(systemName: isLikedByCurrentUser ? "heart.fill" : "heart")
                    .foregroundStyle(isLikedByCurrentUser ? CatchTheme.primary : CatchTheme.textSecondary)
                    .contentTransition(.symbolEffect(.replace))
                if totalLikeCount > 0 {
                    Text("\(totalLikeCount)")
                        .font(.subheadline)
                        .foregroundStyle(CatchTheme.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var commentSummaryLabel: some View {
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

    // MARK: - Comment List

    private var commentList: some View {
        Group {
            if isLoading && comments.isEmpty {
                PawLoadingView()
            } else if comments.isEmpty {
                VStack {
                    Spacer()
                    EmptyStateView(
                        icon: "bubble.right",
                        title: CatchStrings.Interaction.noCommentsTitle,
                        subtitle: CatchStrings.Interaction.noCommentsSubtitle
                    )
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: CatchSpacing.space12) {
                        ForEach(comments) { comment in
                            CommentRowView(
                                comment: comment,
                                currentUserID: currentUserID,
                                onDelete: { deleteComment(comment) }
                            )
                        }

                        loadMoreSection
                    }
                    .padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var loadMoreSection: some View {
        if hasMoreComments {
            if isLoadingMore {
                PawLoadingView(size: .inline)
                    .padding(.vertical, CatchSpacing.space8)
            } else {
                Color.clear
                    .frame(height: 1)
                    .onAppear {
                        Task { await loadMoreComments() }
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
            let (fetched, newCursor) = try await socialService.fetchComments(
                encounterRecordName: encounterRecordName,
                cursor: nil
            )
            comments = fetched
            cursor = newCursor
        } catch {
            // Comments fail silently — not critical
        }
    }

    private func loadMoreComments() async {
        guard let socialService, hasMoreComments, !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let (fetched, newCursor) = try await socialService.fetchComments(
                encounterRecordName: encounterRecordName,
                cursor: cursor
            )
            comments.append(contentsOf: fetched)
            cursor = newCursor
        } catch {
            // Load-more failure is non-critical
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
            } catch {
                comments.insert(removedComment, at: 0)
                toastManager.showError(CatchStrings.Toast.commentDeleteFailed)
            }
        }
    }
}
