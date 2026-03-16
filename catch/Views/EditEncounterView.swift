import SwiftUI
import CatchCore

struct EditEncounterView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(EncounterDataService.self) private var encounterDataService
    @Environment(CatDataService.self) private var catDataService
    @Environment(ToastManager.self) private var toastManager

    private let encounter: Encounter

    @State private var date: Date
    @State private var location: Location
    @State private var notes: String
    @State private var photos: [Data]
    @State private var isSaving = false

    init(encounter: Encounter) {
        self.encounter = encounter
        _date = State(initialValue: encounter.date)
        _location = State(initialValue: encounter.location)
        _notes = State(initialValue: encounter.notes)
        _photos = State(initialValue: [])
    }

    var body: some View {
        NavigationStack {
            Form {
                if let cat = encounter.cat {
                    Section(CatchStrings.Log.catSection) {
                        HStack(spacing: CatchSpacing.space12) {
                            CatPhotoView(photoData: nil, photoUrl: cat.photoUrls.first, size: 40)
                            Text(cat.displayName)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(cat.isUnnamed ? CatchTheme.textSecondary : CatchTheme.textPrimary)
                            Spacer()
                        }
                    }
                }

                Section(CatchStrings.Log.detailsSection) {
                    DatePicker(
                        CatchStrings.Common.date,
                        selection: $date,
                        in: EncounterDateValidator.allowedRange,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    LocationPickerView(location: $location)
                }

                Section(CatchStrings.Log.photosSection) {
                    PhotoPickerView(selectedPhotos: $photos)
                }

                Section(CatchStrings.Log.notesSection) {
                    LimitedTextFieldView(
                        CatchStrings.Log.whatHappenedLower,
                        text: $notes,
                        limit: TextInputLimits.encounterNotes
                    )
                }
            }
            .navigationTitle(CatchStrings.Log.editEncounterTitle)
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
                            .fontWeight(.semibold)
                    }
                }
            }
            .disabled(isSaving)
        }
    }

    private func save() async {
        var updated = encounter
        updated.date = date
        updated.location = location
        updated.notes = notes

        isSaving = true
        defer { isSaving = false }

        do {
            _ = try await encounterDataService.updateEncounter(updated, photos: photos)
            try await catDataService.loadCats()
            dismiss()
        } catch {
            toastManager.showError(CatchStrings.Toast.encounterUpdateFailed)
        }
    }
}
