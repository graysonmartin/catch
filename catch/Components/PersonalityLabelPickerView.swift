import SwiftUI

struct PersonalityLabelPickerView: View {
    @Binding var selectedLabels: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: CatchSpacing.space12) {
            labelSection(CatchStrings.PersonalityLabels.standardHeader, labels: PersonalityLabel.standard)
            labelSection(CatchStrings.PersonalityLabels.weirdHeader, labels: PersonalityLabel.weird)
        }
    }

    private func labelSection(_ header: String, labels: [PersonalityLabel]) -> some View {
        VStack(alignment: .leading, spacing: CatchSpacing.space8) {
            Text(header)
                .font(.caption.weight(.medium))
                .foregroundStyle(CatchTheme.textSecondary)

            WrappingHStack(items: labels, spacing: CatchSpacing.space6) { label in
                labelChip(label)
            }
        }
    }

    private func labelChip(_ label: PersonalityLabel) -> some View {
        let isSelected = selectedLabels.contains(label.rawValue)
        return Button {
            toggle(label)
        } label: {
            Text(label.displayName)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isSelected ? .white : CatchTheme.textPrimary)
                .padding(.horizontal, CatchSpacing.space10)
                .padding(.vertical, CatchSpacing.space6)
                .background(
                    Capsule()
                        .fill(isSelected ? CatchTheme.primary : CatchTheme.primary.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
    }

    private func toggle(_ label: PersonalityLabel) {
        if let index = selectedLabels.firstIndex(of: label.rawValue) {
            selectedLabels.remove(at: index)
        } else {
            selectedLabels.append(label.rawValue)
        }
    }
}

// MARK: - WrappingHStack

private struct WrappingHStack<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let spacing: CGFloat
    let content: (Item) -> Content

    @State private var totalHeight: CGFloat = .zero

    var body: some View {
        GeometryReader { geometry in
            generateContent(in: geometry)
        }
        .frame(height: totalHeight)
    }

    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width: CGFloat = 0
        var height: CGFloat = 0

        return ZStack(alignment: .topLeading) {
            ForEach(items) { item in
                content(item)
                    .padding(.trailing, spacing)
                    .padding(.bottom, spacing)
                    .alignmentGuide(.leading) { dimension in
                        if abs(width - dimension.width) > geometry.size.width {
                            width = 0
                            height -= dimension.height + spacing
                        }
                        let result = width
                        if item.id == items.last?.id {
                            width = 0
                        } else {
                            width -= dimension.width
                        }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if item.id == items.last?.id {
                            height = 0
                        }
                        return result
                    }
            }
        }
        .background(viewHeightReader($totalHeight))
    }

    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        GeometryReader { geometry in
            Color.clear
                .preference(key: HeightPreferenceKey.self, value: geometry.size.height)
                .onPreferenceChange(HeightPreferenceKey.self) { binding.wrappedValue = $0 }
        }
    }
}

private struct HeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
