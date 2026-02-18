import SwiftUI

struct CatPickerView: View {
    let cats: [Cat]
    @Binding var selectedCat: Cat?
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredCats: [Cat] {
        let sorted = cats.sorted { cat1, cat2 in
            let date1 = cat1.lastEncounterDate ?? cat1.createdAt
            let date2 = cat2.lastEncounterDate ?? cat2.createdAt
            return date1 > date2
        }
        if searchText.isEmpty { return sorted }
        let query = searchText.lowercased()
        return sorted.filter {
            $0.name.lowercased().contains(query) ||
            $0.location.name.lowercased().contains(query)
        }
    }

    var body: some View {
        List {
            ForEach(filteredCats) { cat in
                Button {
                    selectedCat = cat
                    dismiss()
                } label: {
                    CatPickerRow(cat: cat, isSelected: cat.id == selectedCat?.id)
                }
                .buttonStyle(.plain)
                .listRowBackground(
                    cat.id == selectedCat?.id
                        ? CatchTheme.secondary.opacity(0.2)
                        : Color.clear
                )
            }
        }
        .listStyle(.plain)
        .overlay {
            if filteredCats.isEmpty && !searchText.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
        .searchable(text: $searchText, prompt: "name or location")
        .navigationTitle("pick a cat")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct CatPickerRow: View {
    let cat: Cat
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            CatPhotoView(photoData: cat.photos.first, size: 48)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(cat.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(CatchTheme.textPrimary)
                    if cat.isOwned {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                            .foregroundStyle(CatchTheme.primary)
                    }
                }

                if !cat.location.name.isEmpty {
                    Label(cat.location.name, systemImage: "mappin")
                        .font(.caption)
                        .foregroundStyle(CatchTheme.textSecondary)
                }

                Label(lastSeenText, systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(CatchTheme.textSecondary)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(CatchTheme.primary)
                    .font(.title3)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private var lastSeenText: String {
        guard let lastDate = cat.lastEncounterDate else {
            return "never seen"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return "last seen " + formatter.localizedString(for: lastDate, relativeTo: Date())
    }
}
