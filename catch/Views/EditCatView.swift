import SwiftUI

struct EditCatView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CKCatSyncService.self) private var catSyncService: CKCatSyncService?
    @Environment(VisionBreedClassifierService.self) private var breedClassifier: VisionBreedClassifierService?
    @Bindable var cat: Cat

    @State private var name: String
    @State private var breed: String?
    @State private var estimatedAge: String
    @State private var location: Location
    @State private var notes: String
    @State private var isOwned: Bool
    @State private var photos: [Data]
    @State private var personalityLabels: [String]
    @State private var breedSuggestion: BreedPrediction?
    @State private var isDismissedSuggestion = false

    init(cat: Cat) {
        self.cat = cat
        _name = State(initialValue: cat.name)
        _breed = State(initialValue: cat.breed)
        _estimatedAge = State(initialValue: cat.estimatedAge)
        _location = State(initialValue: cat.location)
        _notes = State(initialValue: cat.notes)
        _isOwned = State(initialValue: cat.isOwned)
        _photos = State(initialValue: cat.photos)
        _personalityLabels = State(initialValue: cat.personalityLabels)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(CatchStrings.Common.catInfo) {
                    TextField(CatchStrings.Common.name, text: $name)
                    BreedPickerView(breed: $breed)
                    TextField(CatchStrings.Common.estimatedAge, text: $estimatedAge)
                    LocationPickerView(location: $location)
                    Toggle(CatchStrings.Common.iOwnThisCat, isOn: $isOwned)
                }

                Section(CatchStrings.Common.photos) {
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

                Section(CatchStrings.PersonalityLabels.sectionHeader) {
                    PersonalityLabelPickerView(selectedLabels: $personalityLabels)
                }

                Section(CatchStrings.Common.notes) {
                    TextField(CatchStrings.Common.notesPlaceholder, text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(CatchStrings.Log.editCatTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(CatchStrings.Common.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(CatchStrings.Common.save) { save() }
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
        cat.name = name.trimmingCharacters(in: .whitespaces)
        cat.breed = breed
        cat.estimatedAge = estimatedAge
        cat.location = location
        cat.notes = notes
        cat.isOwned = isOwned
        cat.photos = photos
        cat.personalityLabels = personalityLabels
        Task { await catSyncService?.syncCatUpdate(cat) }
        dismiss()
    }
}
