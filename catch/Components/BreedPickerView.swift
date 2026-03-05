import SwiftUI
import CatchCore

struct BreedPickerView: View {
    @Binding var breed: String?

    private var allBreeds: [String] {
        CatBreed.allDisplayNames
    }

    var body: some View {
        Menu {
            ForEach(allBreeds, id: \.self) { name in
                Button(name) {
                    breed = name
                }
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
