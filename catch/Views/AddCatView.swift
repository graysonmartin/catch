import SwiftUI
import SwiftData
import CatchCore

struct AddCatView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(CKCatSyncService.self) private var catSyncService: CKCatSyncService?
    @Environment(VisionBreedClassifierService.self) private var breedClassifier: VisionBreedClassifierService?
    @Environment(ToastManager.self) private var toastManager

    var onSave: (() -> Void)?

    @State private var isUnnamed = false
    @State private var name = ""
    @State private var breed: String?
    @State private var location = Location.empty
    @State private var notes = ""
    @State private var isOwned = false
    @State private var photos: [Data] = []
    @State private var breedSuggestion: BreedPrediction?
    @State private var isDismissedSuggestion = false
    @State private var showStevenEasterEgg = false
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    formSections
                    locationSection
                }
            }
            .background(CatchTheme.background)
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
        }
        .scrollDisabled(true)
        .frame(minHeight: 500)
    }

    // MARK: - Location Section (outside Form)

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: CatchSpacing.space12) {
            Text(CatchStrings.Common.location)
                .font(.footnote)
                .foregroundStyle(CatchTheme.textSecondary)
                .textCase(.uppercase)
                .padding(.horizontal, CatchSpacing.space20)

            VStack(alignment: .leading, spacing: CatchSpacing.space12) {
                LocationPickerView(location: $location)
            }
            .padding(CatchSpacing.space20)
            .background(CatchTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusSmall))
            .padding(.horizontal)
        }
        .padding(.bottom, CatchSpacing.space16)
    }

    // MARK: - Logic

    private var canSave: Bool {
        (isUnnamed || !name.trimmingCharacters(in: .whitespaces).isEmpty) && !photos.isEmpty
    }

    private func save() async {
        let trimmedName = isUnnamed ? nil : name.trimmingCharacters(in: .whitespaces)
        let cat = Cat(
            name: trimmedName,
            breed: breed,
            estimatedAge: "",
            location: location,
            notes: notes,
            isOwned: isOwned,
            photos: photos
        )

        let encounter = Encounter(
            date: Date(),
            location: location,
            notes: "",
            cat: cat,
            photos: photos
        )

        isSaving = true
        defer { isSaving = false }

        do {
            try await catSyncService?.syncNewCat(cat, firstEncounter: encounter)
        } catch {
            toastManager.showError(CatchStrings.Toast.catSyncFailed)
            return
        }

        modelContext.insert(cat)
        modelContext.insert(encounter)
        onSave?()

        if cat.isSteven {
            showStevenEasterEgg = true
        } else {
            dismiss()
        }
    }
}
