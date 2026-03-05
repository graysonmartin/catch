import SwiftUI
import CatchCore

struct EditEncounterView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CKEncounterSyncService.self) private var encounterSyncService: CKEncounterSyncService?
    @Environment(ToastManager.self) private var toastManager
    @Bindable var encounter: Encounter

    @State private var date: Date
    @State private var location: Location
    @State private var notes: String
    @State private var photos: [Data]
    @State private var isSaving = false

    // Original values for rollback
    private let originalDate: Date
    private let originalLocation: Location
    private let originalNotes: String
    private let originalPhotos: [Data]

    init(encounter: Encounter) {
        self.encounter = encounter
        _date = State(initialValue: encounter.date)
        _location = State(initialValue: encounter.location)
        _notes = State(initialValue: encounter.notes)
        _photos = State(initialValue: encounter.photos)

        originalDate = encounter.date
        originalLocation = encounter.location
        originalNotes = encounter.notes
        originalPhotos = encounter.photos
    }

    var body: some View {
        NavigationStack {
            Form {
                if let cat = encounter.cat {
                    Section(CatchStrings.Log.catSection) {
                        HStack(spacing: CatchSpacing.space12) {
                            CatPhotoView(photoData: cat.photos.first, size: 40)
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
        encounter.date = date
        encounter.location = location
        encounter.notes = notes
        encounter.photos = photos

        isSaving = true
        defer { isSaving = false }

        do {
            try await encounterSyncService?.syncEncounterUpdate(encounter)
        } catch {
            // Revert local changes
            encounter.date = originalDate
            encounter.location = originalLocation
            encounter.notes = originalNotes
            encounter.photos = originalPhotos
            toastManager.showError(CatchStrings.Toast.encounterUpdateFailed)
            return
        }

        dismiss()
    }
}
