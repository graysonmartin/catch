import SwiftUI
import CatchCore

struct CommentInputBar: View {
    @Binding var text: String
    let onSubmit: () -> Void

    @FocusState private var isFocused: Bool

    private var canSubmit: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: CatchSpacing.space4) {
            HStack(alignment: .bottom, spacing: CatchSpacing.space8) {
                TextField(CatchStrings.Interaction.addComment, text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...6)
                    .font(.subheadline)
                    .padding(.vertical, CatchSpacing.space8)
                    .focused($isFocused)
                    .submitLabel(.send)
                    .onSubmit { onSubmit() }
                    .onChange(of: text) { _, newValue in
                        if newValue.count > TextInputLimits.comment {
                            text = TextInputLimits.enforceLimit(
                                text: newValue,
                                limit: TextInputLimits.comment
                            )
                        }
                    }

                Button {
                    onSubmit()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(canSubmit ? CatchTheme.primary : CatchTheme.textSecondary.opacity(0.3))
                }
                .disabled(!canSubmit)
                .buttonStyle(.plain)
                .padding(.bottom, CatchSpacing.space6)
            }

            if TextInputLimits.shouldShowCount(text: text, limit: TextInputLimits.comment) {
                characterCounter
            }
        }
        .padding(.horizontal)
        .padding(.vertical, CatchSpacing.space4)
        .background(CatchTheme.cardBackground)
    }

    // MARK: - Character Counter

    private var characterCounter: some View {
        Text(counterText)
            .font(.caption2)
            .foregroundStyle(
                TextInputLimits.isAtLimit(text: text, limit: TextInputLimits.comment)
                    ? CatchTheme.primary
                    : CatchTheme.textSecondary
            )
            .monospacedDigit()
    }

    private var counterText: String {
        let remaining = TextInputLimits.remaining(text: text, limit: TextInputLimits.comment)
        if remaining == 0 {
            return CatchStrings.TextInput.limitReached
        }
        return CatchStrings.TextInput.charactersRemaining(remaining)
    }

    // MARK: - Public API

    func dismissKeyboard() {
        isFocused = false
    }
}
