import SwiftUI
import CatchCore

struct AddCatView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CatDataService.self) private var catDataService
    @Environment(FeedDataService.self) private var feedDataService
    @Environment(VisionBreedClassifierService.self) private var breedClassifier: VisionBreedClassifierService?
    @Environment(ToastManager.self) private var toastManager

    var onSave: (() -> Void)?

    @State private var isUnnamed = false
    @State private var name = ""
    @State private var breed: String?
    @State private var location = Location.empty
    @State private var notes = ""
    @State private var isOwned = false
    @State private var photos: [PhotoItem] = []
    @State private var encounterDate = Date()
    @State private var breedSuggestion: BreedPrediction?
    @State private var isDismissedSuggestion = false
    @State private var showStevenEasterEgg = false
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section(CatchStrings.Common.photos) {
                    PhotoPickerView(
                        selectedPhotos: $photos,
                        thumbnailSize: 120,
                        showsProfilePicBadge: true
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

                Section(CatchStrings.Log.detailsSection) {
                    VStack(alignment: .leading, spacing: CatchSpacing.space4) {
                        LimitedSingleLineFieldView(
                            CatchStrings.Common.name,
                            text: $name,
                            limit: TextInputLimits.catName
                        )
                        if isUnnamed {
                            Text(CatchStrings.Common.strayNameHint)
                                .font(.caption)
                                .foregroundStyle(CatchTheme.textSecondary)
                        }
                    }
                    BreedPickerView(breed: $breed)
                }

                Section(CatchStrings.Log.encounterDetails) {
                    DatePicker(
                        CatchStrings.Common.date,
                        selection: $encounterDate,
                        in: EncounterDateValidator.allowedRange,
                        displayedComponents: [.date, .hourAndMinute]
                    )
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
            .navigationTitle(CatchStrings.Log.newCat)
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
            .onChange(of: photos) {
                let localPhotos = photos.localData
                guard breed == nil, !isDismissedSuggestion, !localPhotos.isEmpty else { return }
                Task {
                    breedSuggestion = await breedClassifier?.classifyBest(imageDataArray: localPhotos)
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

    private func save() async {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let trimmedName = trimmed.isEmpty ? nil : trimmed

        isSaving = true
        defer { isSaving = false }

        do {
            let cat = try await catDataService.createCat(
                name: trimmedName,
                breed: breed,
                location: location,
                notes: notes,
                isOwned: isOwned,
                photos: photos.localData,
                encounterDate: encounterDate
            )
            if var encounter = cat.encounters.first {
                encounter.cat = cat
                feedDataService.prependEncounter(encounter)
            }
            onSave?()

            if cat.isSteven {
                showStevenEasterEgg = true
            } else {
                dismiss()
            }
        } catch {
            toastManager.showError(CatchStrings.Toast.catSyncFailed)
        }
    }
}
