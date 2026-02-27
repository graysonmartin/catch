import SwiftUI
import CatchCore

struct BreedPickerView: View {
    @Binding var breed: String?
    @State private var isCustomEntry = false
    @State private var customBreed = ""

    private var allBreeds: [String] {
        BreedLabelMapper.allDisplayNames
    }

    var body: some View {
        if isCustomEntry {
            HStack {
                TextField(CatchStrings.Components.breedName, text: $customBreed)
                    .textInputAutocapitalization(.words)
                    .onSubmit {
                        let trimmed = customBreed.trimmingCharacters(in: .whitespaces)
                        breed = trimmed.isEmpty ? nil : trimmed
                        isCustomEntry = false
                    }
                Button(CatchStrings.Common.done) {
                    let trimmed = customBreed.trimmingCharacters(in: .whitespaces)
                    breed = trimmed.isEmpty ? nil : trimmed
                    isCustomEntry = false
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(CatchTheme.primary)
            }
        } else {
            Menu {
                ForEach(allBreeds, id: \.self) { name in
                    Button(name) {
                        breed = name
                    }
                }

                Divider()

                Button(CatchStrings.Components.somethingElse) {
                    customBreed = breed ?? ""
                    isCustomEntry = true
                }

                if breed != nil {
                    Divider()
                    Button(CatchStrings.Components.clear, role: .destructive) {
                        breed = nil
                    }
                }
            } label: {
                HStack {
                    Text(CatchStrings.Common.breed)
                        .foregroundStyle(CatchTheme.textPrimary)
                    Spacer()
                    Text(breed ?? CatchStrings.Components.unknown)
                        .foregroundStyle(breed != nil ? CatchTheme.textPrimary : CatchTheme.textSecondary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundStyle(CatchTheme.textSecondary)
                }
            }
        }
    }
}
