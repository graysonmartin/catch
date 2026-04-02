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
                TextEditor(text: $text)
                    .font(.subheadline)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 20, maxHeight: 120)
                    .fixedSize(horizontal: false, vertical: true)
                    .focused($isFocused)
                    .overlay(alignment: .topLeading) {
                        if text.isEmpty {
                            Text(CatchStrings.Interaction.addComment)
                                .font(.subheadline)
                                .foregroundStyle(CatchTheme.textSecondary.opacity(0.5))
                                .padding(.leading, 5)
                                .padding(.top, 8)
                                .allowsHitTesting(false)
                        }
                    }
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
                        .frame(minWidth: CatchTheme.minTapTarget, minHeight: CatchTheme.minTapTarget)
                }
                .disabled(!canSubmit)
                .buttonStyle(.plain)
                .accessibilityLabel(CatchStrings.Accessibility.submitComment)
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
