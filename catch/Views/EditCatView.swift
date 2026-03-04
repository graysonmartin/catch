import SwiftUI
import CatchCore

struct EditCatView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CKCatSyncService.self) private var catSyncService: CKCatSyncService?
    @Environment(VisionBreedClassifierService.self) private var breedClassifier: VisionBreedClassifierService?
    @Bindable var cat: Cat

    @State private var isUnnamed: Bool
    @State private var name: String
    @State private var breed: String?
    @State private var estimatedAge: String
    @State private var location: Location
    @State private var notes: String
    @State private var isOwned: Bool
    @State private var photos: [Data]
    @State private var breedSuggestion: BreedPrediction?
    @State private var isDismissedSuggestion = false

    init(cat: Cat) {
        self.cat = cat
        _isUnnamed = State(initialValue: cat.name == nil)
        _name = State(initialValue: cat.name ?? "")
        _breed = State(initialValue: cat.breed)
        _estimatedAge = State(initialValue: cat.estimatedAge)
        _location = State(initialValue: cat.location)
        _notes = State(initialValue: cat.notes)
        _isOwned = State(initialValue: cat.isOwned)
        _photos = State(initialValue: cat.photos)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(CatchStrings.Common.catInfo) {
                    Toggle(CatchStrings.Common.unnamedStray, isOn: $isUnnamed)
                    if !isUnnamed {
                        LimitedSingleLineFieldView(
                            CatchStrings.Common.name,
                            text: $name,
                            limit: TextInputLimits.catName
                        )
                    }
                    BreedPickerView(breed: $breed)
                    TextField(CatchStrings.Common.estimatedAge, text: $estimatedAge)
                    LocationPickerView(location: $location)
                    Toggle(CatchStrings.Common.iOwnThisCat, isOn: $isOwned)
                }

                Section(CatchStrings.Common.photos) {
                    PhotoPickerView(selectedPhotos: $photos, minimumPhotos: 1)
                    if photos.isEmpty {
                        Text(CatchStrings.Log.photoRequired)
                            .font(.caption)
                            .foregroundStyle(CatchTheme.primary)
                    }
                    if breed == nil && !isDismissedSuggestion {
                        BreedSuggestionView(
                            prediction: breedSuggestion,
                            isClassifying: breedClassifier?.isClassifying ?? false,
                            debugPredictions: {
                                #if DEBUG
                                return breedClassifier?.debugTopPredictions ?? []
                                #else
                                return []
                                #endif
                            }(),
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

                Section(CatchStrings.Common.notes) {
                    LimitedTextFieldView(
                        CatchStrings.Common.notesPlaceholder,
                        text: $notes,
                        limit: TextInputLimits.catNotes
                    )
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
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
            .onChange(of: isUnnamed) {
                if isUnnamed { name = "" }
            }
            .onChange(of: photos) {
                guard breed == nil, !isDismissedSuggestion, !photos.isEmpty else { return }
                Task {
                    breedSuggestion = await breedClassifier?.classifyBest(imageDataArray: photos)
                }
            }
        }
    }

    private var canSave: Bool {
        (isUnnamed || !name.trimmingCharacters(in: .whitespaces).isEmpty) && !photos.isEmpty
    }

    private func save() {
        cat.name = isUnnamed ? nil : name.trimmingCharacters(in: .whitespaces)
        cat.breed = breed
        cat.estimatedAge = estimatedAge
        cat.location = location
        cat.notes = notes
        cat.isOwned = isOwned
        cat.photos = photos
        Task { await catSyncService?.syncCatUpdate(cat) }
        dismiss()
    }
}
