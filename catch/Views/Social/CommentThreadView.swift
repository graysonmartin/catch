import SwiftUI
import CatchCore

struct CommentThreadView: View {
    let encounterRecordName: String
    var showInteractionBar: Bool = false

    @Environment(CKSocialInteractionService.self) private var socialService: CKSocialInteractionService?
    @Environment(AppleAuthService.self) private var authService

    @State private var comments: [EncounterComment] = []
    @State private var newCommentText = ""
    @State private var isLoading = false
    @State private var cursor: String?
    @FocusState private var isInputFocused: Bool

    private var currentUserID: String? {
        authService.authState.user?.userIdentifier
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
                inputBar
            }
            .background(CatchTheme.background)
            .navigationTitle(CatchStrings.Interaction.comments)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(CatchStrings.Common.done) {
                        isInputFocused = false
                    }
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

    // MARK: - Subviews

    private var commentList: some View {
        Group {
            if isLoading && comments.isEmpty {
                VStack {
                    Spacer()
                    ProgressView()
                        .tint(CatchTheme.primary)
                    Spacer()
                }
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
                    }
                    .padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var inputBar: some View {
        HStack(spacing: CatchSpacing.space8) {
            TextField(CatchStrings.Interaction.addComment, text: $newCommentText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .font(.subheadline)
                .focused($isInputFocused)

            Button {
                Task { await submitComment() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(canSubmit ? CatchTheme.primary : CatchTheme.textSecondary.opacity(0.3))
            }
            .disabled(!canSubmit)
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.vertical, CatchSpacing.space8)
        .background(CatchTheme.cardBackground)
    }

    // MARK: - Helpers

    private var canSubmit: Bool {
        !newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

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

    private func submitComment() async {
        guard let socialService else { return }
        let text = newCommentText
        newCommentText = ""

        do {
            let comment = try await socialService.addComment(
                encounterRecordName: encounterRecordName,
                text: text
            )
            comments.insert(comment, at: 0)
        } catch {
            newCommentText = text
        }
    }

    private func deleteComment(_ comment: EncounterComment) {
        guard let socialService else { return }
        comments.removeAll { $0.id == comment.id }
        Task {
            try? await socialService.deleteComment(
                recordName: comment.id,
                encounterRecordName: encounterRecordName
            )
        }
    }
}
