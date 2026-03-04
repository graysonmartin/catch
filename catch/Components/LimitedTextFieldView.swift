import SwiftUI
import CatchCore

/// A text field with an enforced character limit and a remaining-count indicator.
///
/// Shows a counter near the limit (at `TextInputLimits.warningThreshold`). Truncates
/// input that exceeds the limit.
struct LimitedTextFieldView: View {
    private let placeholder: String
    private let limit: Int
    private let lineRange: ClosedRange<Int>

    @Binding private var text: String

    init(
        _ placeholder: String,
        text: Binding<String>,
        limit: Int,
        lineRange: ClosedRange<Int> = 3...6
    ) {
        self.placeholder = placeholder
        self._text = text
        self.limit = limit
        self.lineRange = lineRange
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: CatchSpacing.space4) {
            TextField(placeholder, text: $text, axis: .vertical)
                .lineLimit(lineRange)
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
