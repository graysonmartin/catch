import SwiftUI
import CatchCore

/// A single-line text field with an enforced character limit and a remaining-count indicator.
///
/// Use this for short fields like cat name. For multi-line text areas, use `LimitedTextFieldView`.
struct LimitedSingleLineFieldView: View {
    private let placeholder: String
    private let limit: Int

    @Binding private var text: String

    init(_ placeholder: String, text: Binding<String>, limit: Int) {
        self.placeholder = placeholder
        self._text = text
        self.limit = limit
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: CatchSpacing.space4) {
            TextField(placeholder, text: $text)
                .onChange(of: text) { _, newValue in
                    if newValue.count > limit {
                        text = TextInputLimits.enforceLimit(text: newValue, limit: limit)
                    }
                }

            if TextInputLimits.shouldShowCount(text: text, limit: limit) {
                characterCounter
            }
        }
    }

    // MARK: - Subviews

    private var characterCounter: some View {
        Text(counterText)
            .font(.caption2)
            .foregroundStyle(isAtLimit ? CatchTheme.primary : CatchTheme.textSecondary)
            .monospacedDigit()
    }

    // MARK: - Helpers

    private var isAtLimit: Bool {
        TextInputLimits.isAtLimit(text: text, limit: limit)
    }

    private var counterText: String {
        let remaining = TextInputLimits.remaining(text: text, limit: limit)
        if remaining == 0 {
            return CatchStrings.TextInput.limitReached
        }
        return CatchStrings.TextInput.charactersRemaining(remaining)
    }
}
