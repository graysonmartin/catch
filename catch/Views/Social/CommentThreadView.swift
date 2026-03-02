import SwiftUI
import CatchCore

struct CommentThreadView: View {
    let encounterRecordName: String

    @Environment(CKSocialInteractionService.self) private var socialService: CKSocialInteractionService?
    @Environment(AppleAuthService.self) private var authService

    @State private var comments: [EncounterComment] = []
    @State private var newCommentText = ""
    @State private var isLoading = false
    @State private var cursor: String?
    @State private var rateLimitMessage: String?
    @State private var isSubmitDisabled = false
    @FocusState private var isInputFocused: Bool

    private var currentUserID: String? {
        authService.authState.user?.userIdentifier
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
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
        VStack(alignment: .leading, spacing: CatchSpacing.space4) {
            if let rateLimitMessage {
                Text(rateLimitMessage)
                    .font(.caption2)
                    .foregroundStyle(CatchTheme.textSecondary)
                    .padding(.horizontal)
                    .transition(.opacity)
            }

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
        }
        .background(CatchTheme.cardBackground)
        .animation(.easeInOut(duration: 0.2), value: rateLimitMessage)
    }

    // MARK: - Helpers

    private var canSubmit: Bool {
        !newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSubmitDisabled
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
            rateLimitMessage = nil
        } catch let error as SocialInteractionError {
            if case .rateLimited = error {
                newCommentText = text
                showCommentCooldown()
            } else {
                newCommentText = text
            }
        } catch {
            newCommentText = text
        }
    }

    private func showCommentCooldown() {
        rateLimitMessage = CatchStrings.RateLimit.commentCooldown
        isSubmitDisabled = true
        Task {
            try? await Task.sleep(for: .seconds(5))
            rateLimitMessage = nil
            isSubmitDisabled = false
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
