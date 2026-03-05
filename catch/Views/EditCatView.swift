import SwiftUI
import CatchCore

struct EditCatView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CKCatSyncService.self) private var catSyncService: CKCatSyncService?
    @Environment(VisionBreedClassifierService.self) private var breedClassifier: VisionBreedClassifierService?
    @Environment(ToastManager.self) private var toastManager
    @Bindable var cat: Cat

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

    // Original values for rollback
    private let originalName: String?
    private let originalBreed: String?
    private let originalLocation: Location
    private let originalNotes: String
    private let originalIsOwned: Bool
    private let originalPhotos: [Data]

    init(cat: Cat) {
        self.cat = cat
        _isUnnamed = State(initialValue: cat.name == nil)
        _name = State(initialValue: cat.name ?? "")
        _breed = State(initialValue: cat.breed)
        _location = State(initialValue: cat.location)
        _notes = State(initialValue: cat.notes)
        _isOwned = State(initialValue: cat.isOwned)
        _photos = State(initialValue: cat.photos)

        originalName = cat.name
        originalBreed = cat.breed
        originalLocation = cat.location
        originalNotes = cat.notes
        originalIsOwned = cat.isOwned
        originalPhotos = cat.photos
    }

    var body: some View {
        NavigationStack {
            formSections
            .background(CatchTheme.background)
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

    // MARK: - Form Sections

    private var formSections: some View {
        Form {
            Section(CatchStrings.Common.photos) {
                PhotoPickerView(
                    selectedPhotos: $photos,
                    minimumPhotos: 1,
                    thumbnailSize: 120
                )
                if photos.isEmpty {
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

            Section(CatchStrings.Common.notes) {
                LimitedTextFieldView(
                    CatchStrings.Common.notesPlaceholder,
                    text: $notes,
                    limit: TextInputLimits.catNotes
                )
            }

            Section(CatchStrings.Common.location) {
                LocationPickerView(location: $location)
            }
        }
    }

    // MARK: - Logic

    private var canSave: Bool {
        (isUnnamed || !name.trimmingCharacters(in: .whitespaces).isEmpty) && !photos.isEmpty
    }

    private func save() async {
        cat.name = isUnnamed ? nil : name.trimmingCharacters(in: .whitespaces)
        cat.breed = breed
        cat.location = location
        cat.notes = notes
        cat.isOwned = isOwned
        cat.photos = photos

        isSaving = true
        defer { isSaving = false }

        do {
            try await catSyncService?.syncCatUpdate(cat)
        } catch {
            // Revert local changes
            cat.name = originalName
            cat.breed = originalBreed
            cat.location = originalLocation
            cat.notes = originalNotes
            cat.isOwned = originalIsOwned
            cat.photos = originalPhotos
            toastManager.showError(CatchStrings.Toast.catUpdateFailed)
            return
        }

        dismiss()
    }
}
