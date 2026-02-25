import SwiftUI
import SwiftData

struct AddCatView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(CKCatSyncService.self) private var catSyncService: CKCatSyncService?
    @Environment(VisionBreedClassifierService.self) private var breedClassifier: VisionBreedClassifierService?

    @State private var name = ""
    @State private var breed: String?
    @State private var estimatedAge = ""
    @State private var location = Location.empty
    @State private var notes = ""
    @State private var isOwned = false
    @State private var photos: [Data] = []
    @State private var breedSuggestion: BreedPrediction?
    @State private var isDismissedSuggestion = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Cat Info") {
                    TextField("Name", text: $name)
                    BreedPickerView(breed: $breed)
                    TextField("Estimated Age", text: $estimatedAge)
                    LocationPickerView(location: $location)
                    Toggle("I own this cat", isOn: $isOwned)
                }

                Section("Photos") {
                    PhotoPickerView(selectedPhotos: $photos)
                    if breed == nil && !isDismissedSuggestion {
                        BreedSuggestionView(
                            prediction: breedSuggestion,
                            isClassifying: breedClassifier?.isClassifying ?? false,
                            onConfirm: { confirmedBreed in
                                breed = confirmedBreed
                                breedSuggestion = nil
                            },
                            onDismiss: {
                                isDismissedSuggestion = true
                                breedSuggestion = nil
                            }
                        )
                    }
                }

                Section("Notes") {
                    TextField("Notes about this cat...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("First Encounter") {
                    Text("A first encounter will be logged automatically with today's date and the location above.")
                        .font(.caption)
                        .foregroundStyle(CatchTheme.textSecondary)
                }
            }
            .navigationTitle("New Cat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                        .fontWeight(.semibold)
                }
            }
            .onChange(of: photos) {
                guard breed == nil, !isDismissedSuggestion, !photos.isEmpty else { return }
                Task {
                    breedSuggestion = await breedClassifier?.classifyBest(imageDataArray: photos)
                }
            }
        }
    }

    private func save() {
        let cat = Cat(
            name: name.trimmingCharacters(in: .whitespaces),
            breed: breed,
            estimatedAge: estimatedAge,
            location: location,
            notes: notes,
            isOwned: isOwned,
            photos: photos
        )
        modelContext.insert(cat)

        let encounter = Encounter(
            date: Date(),
            location: location,
            notes: "",
            cat: cat,
            photos: photos
        )
        modelContext.insert(encounter)

        Task { await catSyncService?.syncNewCat(cat, firstEncounter: encounter) }
        dismiss()
    }
}
