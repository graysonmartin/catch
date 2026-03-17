import SwiftUI
import CatchCore

struct EditCatView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CatDataService.self) private var catDataService
    @Environment(VisionBreedClassifierService.self) private var breedClassifier: VisionBreedClassifierService?
    @Environment(ToastManager.self) private var toastManager

    private let cat: Cat

    @State private var isUnnamed: Bool
    @State private var name: String
    @State private var breed: String?
    @State private var location: Location
    @State private var notes: String
    @State private var isOwned: Bool
    @State private var photos: [Data]
    @State private var breedSuggestion: BreedPrediction?
    @State private var isDismissedSuggestion = false
    @State private var isSaving = false

    init(cat: Cat) {
        self.cat = cat
        _isUnnamed = State(initialValue: cat.name == nil)
        _name = State(initialValue: cat.name ?? "")
        _breed = State(initialValue: cat.breed)
        _location = State(initialValue: cat.location)
        _notes = State(initialValue: cat.notes)
        _isOwned = State(initialValue: cat.isOwned)
        _photos = State(initialValue: [])
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(CatchStrings.Common.photos) {
                    PhotoPickerView(
                        selectedPhotos: $photos,
                        thumbnailSize: 120
                    )
                    if photos.isEmpty && cat.photoUrls.isEmpty {
                        Text(CatchStrings.Log.photoRequired)
                            .font(.caption)
                            .foregroundStyle(CatchTheme.primary)
                    }
                    if breed == nil && !isDismissedSuggestion
                        && (breedSuggestion != nil || breedClassifier?.isClassifying == true)
                    {
                        BreedPredictionCard(
                            predictions: breedClassifier?.topPredictions ?? [],
                            isClassifying: breedClassifier?.isClassifying ?? false,
                            onSelect: { breed = $0; breedSuggestion = nil },
                            onDismiss: { isDismissedSuggestion = true; breedSuggestion = nil }
                        )
                    }
                }

                Section {
                    Toggle(CatchStrings.Common.unnamedStray, isOn: $isUnnamed)
                    Toggle(CatchStrings.Common.iOwnThisCat, isOn: $isOwned)
                }

                Section {
                    if !isUnnamed {
                        LimitedSingleLineFieldView(
                            CatchStrings.Common.name,
                            text: $name,
                            limit: TextInputLimits.catName
                        )
                    }
                    BreedPickerView(breed: $breed)
                }

                Section(CatchStrings.Common.location) {
                    LocationPickerView(location: $location)
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
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button(CatchStrings.Common.save) { Task { await save() } }
                            .disabled(!canSave)
                            .fontWeight(.semibold)
                    }
                }
            }
            .disabled(isSaving)
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
        (isUnnamed || !name.trimmingCharacters(in: .whitespaces).isEmpty)
            && (!photos.isEmpty || !cat.photoUrls.isEmpty)
    }

    private func save() async {
        var updatedCat = cat
        updatedCat.name = isUnnamed ? nil : name.trimmingCharacters(in: .whitespaces)
        updatedCat.breed = breed
        updatedCat.location = location
        updatedCat.notes = notes
        updatedCat.isOwned = isOwned

        isSaving = true
        defer { isSaving = false }

        do {
            _ = try await catDataService.updateCat(updatedCat, photos: photos)
            dismiss()
        } catch {
            toastManager.showError(CatchStrings.Toast.catUpdateFailed)
        }
    }
}
