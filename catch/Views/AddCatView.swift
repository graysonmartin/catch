import SwiftUI
import SwiftData
import CatchCore

struct AddCatView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(CKCatSyncService.self) private var catSyncService: CKCatSyncService?
    @Environment(VisionBreedClassifierService.self) private var breedClassifier: VisionBreedClassifierService?

    var onSave: (() -> Void)?

    @State private var isUnnamed = false
    @State private var name = ""
    @State private var breed: String?
    @State private var estimatedAge = ""
    @State private var location = Location.empty
    @State private var notes = ""
    @State private var isOwned = false
    @State private var photos: [Data] = []
    @State private var breedSuggestion: BreedPrediction?
    @State private var isDismissedSuggestion = false
    @State private var showStevenEasterEgg = false

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
                    PhotoPickerView(selectedPhotos: $photos)
                    if photos.isEmpty {
                        Text(CatchStrings.Log.photoRequired)
                            .font(.caption)
                            .foregroundStyle(CatchTheme.primary)
                    }
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

                Section(CatchStrings.Common.notes) {
                    LimitedTextFieldView(
                        CatchStrings.Common.notesPlaceholder,
                        text: $notes,
                        limit: TextInputLimits.catNotes
                    )
                }

            }
            .navigationTitle(CatchStrings.Log.newCat)
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
            .overlay {
                if showStevenEasterEgg {
                    StevenEasterEggView {
                        dismiss()
                    }
                }
            }
        }
    }

    private var canSave: Bool {
        (isUnnamed || !name.trimmingCharacters(in: .whitespaces).isEmpty) && !photos.isEmpty
    }

    private func save() {
        let trimmedName = isUnnamed ? nil : name.trimmingCharacters(in: .whitespaces)
        let cat = Cat(
            name: trimmedName,
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

        onSave?()

        if cat.isSteven {
            showStevenEasterEgg = true
        } else {
            dismiss()
        }
    }
}
