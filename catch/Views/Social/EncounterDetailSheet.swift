import SwiftUI
import CatchCore

struct EncounterDetailSheet: View {
    let data: EncounterDetailData

    @Environment(CKSocialInteractionService.self) private var socialService: CKSocialInteractionService?
    @Environment(AppleAuthService.self) private var authService
    @Environment(ToastManager.self) private var toastManager
    @Environment(\.dismiss) private var dismiss

    @State private var comments: [EncounterComment] = []
    @State private var newCommentText = ""
    @State private var isLoading = false
    @State private var showLikedBySheet = false

    private var currentUserID: String? {
        authService.authState.user?.userIdentifier
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
                    Button(CatchStrings.Common.done) { dismiss() }
                }
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

    // MARK: - Scroll Content

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if !data.photos.isEmpty {
                    PhotoCarouselView(photos: data.photos, height: 260, isTappable: true)
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

    // MARK: - Breed, Location & Notes

    private var breedRow: some View {
        Label(data.breed, systemImage: "pawprint.fill")
            .font(.subheadline)
            .foregroundStyle(CatchTheme.textSecondary)
    }

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
            likeSection
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
                Button {
                    showLikedBySheet = true
                } label: {
                    Text("\(totalLikeCount)")
                        .font(.subheadline)
                        .foregroundStyle(CatchTheme.textSecondary)
                }
                .buttonStyle(.plain)
            }
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
