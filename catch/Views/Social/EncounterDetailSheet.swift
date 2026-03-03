import SwiftUI
import CatchCore

struct EncounterDetailSheet: View {
    let data: EncounterDetailData

    @Environment(CKSocialInteractionService.self) private var socialService: CKSocialInteractionService?
    @Environment(AppleAuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss

    @State private var comments: [EncounterComment] = []
    @State private var newCommentText = ""
    @State private var isLoading = false
    @FocusState private var isInputFocused: Bool

    private var currentUserID: String? {
        authService.authState.user?.userIdentifier
    }

    private var encounterRecordName: String { data.id }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                scrollContent
                Divider()
                inputBar
            }
            .background(CatchTheme.background)
            .navigationTitle(CatchStrings.Diary.encounterDetail)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(CatchStrings.Common.done) { dismiss() }
                }
            }
            .presentationDetents([.medium, .large])
            .task { await loadComments() }
        }
    }

    // MARK: - Scroll Content

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if !data.photos.isEmpty {
                    PhotoCarouselView(photos: data.photos, height: 220)
                        .padding(.bottom, CatchSpacing.space12)
                }

                catHeader
                    .padding(.horizontal)
                    .padding(.bottom, CatchSpacing.space8)

                if !data.locationName.isEmpty {
                    locationRow
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
            CatPhotoView(photoData: data.catPhotoData, size: 40)

            VStack(alignment: .leading, spacing: CatchSpacing.space2) {
                HStack(spacing: CatchSpacing.space4) {
                    Text(data.catName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(data.isUnnamed ? CatchTheme.textSecondary : CatchTheme.textPrimary)

                    encounterPill

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

    private var encounterPill: some View {
        Text(data.isFirstEncounter ? CatchStrings.Feed.pillNew : CatchStrings.Feed.pillRepeat)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(data.isFirstEncounter ? CatchTheme.primary : CatchTheme.textSecondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(data.isFirstEncounter
                        ? CatchTheme.primary.opacity(0.15)
                        : CatchTheme.textSecondary.opacity(0.1))
            )
    }

    // MARK: - Location & Notes

    private var locationRow: some View {
        Label(data.locationName, systemImage: "mappin")
            .font(.subheadline)
            .foregroundStyle(CatchTheme.textSecondary)
    }

    private var notesRow: some View {
        Text(data.notes)
            .font(.subheadline)
            .foregroundStyle(CatchTheme.textPrimary)
    }

    // MARK: - Interaction

    private var interactionRow: some View {
        HStack(spacing: CatchSpacing.space16) {
            likeButton
            commentCountLabel
            Spacer()
        }
    }

    private var likeButton: some View {
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
            HStack {
                Spacer()
                ProgressView()
                    .tint(CatchTheme.primary)
                Spacer()
            }
            .padding(.vertical, CatchSpacing.space24)
        } else if comments.isEmpty {
            EmptyStateView(
                icon: "bubble.right",
                title: CatchStrings.Interaction.noCommentsTitle,
                subtitle: CatchStrings.Interaction.noCommentsSubtitle
            )
            .padding(.vertical, CatchSpacing.space12)
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

    // MARK: - Input Bar

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

    private var canSubmit: Bool {
        !newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
