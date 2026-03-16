import SwiftUI
import SwiftData
import CatchCore

struct LogEncounterView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(DefaultEncounterSyncService.self) private var encounterSyncService: DefaultEncounterSyncService?
    @Environment(ToastManager.self) private var toastManager
    @Query(sort: \Cat.name) private var cats: [Cat]

    @State private var selectedCat: Cat?
    @State private var date = Date()
    @State private var location = Location.empty
    @State private var notes = ""
    @State private var photos: [Data] = []
    @State private var showingAddCat = false
    @State private var isSaving = false

    var onSave: (() -> Void)?
    var preselectedCat: Cat? = nil

    var body: some View {
        NavigationStack {
            Form {
                if preselectedCat != nil {
                    Section {
                        if let cat = selectedCat {
                            HStack(spacing: CatchSpacing.space12) {
                                CatPhotoView(photoData: cat.photos.first, size: 40)

                                VStack(alignment: .leading, spacing: CatchSpacing.space2) {
                                    Text(CatchStrings.Log.loggingFor)
                                        .font(.caption)
                                        .foregroundStyle(CatchTheme.textSecondary)
                                    Text(cat.displayName)
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(cat.isUnnamed ? CatchTheme.textSecondary : CatchTheme.textPrimary)
                                }
                                Spacer()
                            }
                        }
                    }
                } else {
                    Section(CatchStrings.Log.whichCat) {
                        if cats.isEmpty {
                            VStack(alignment: .leading, spacing: CatchSpacing.space8) {
                                Text(CatchStrings.Log.noCatsRegistered)
                                    .foregroundStyle(CatchTheme.textSecondary)
                                Button {
                                    showingAddCat = true
                                } label: {
                                    Label(CatchStrings.Log.registerOneNow, systemImage: "plus.circle.fill")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(CatchTheme.primary)
                                }
                            }
                        } else {
                            NavigationLink {
                                CatPickerView(cats: cats, selectedCat: $selectedCat)
                            } label: {
                                if let cat = selectedCat {
                                    HStack(spacing: CatchSpacing.space12) {
                                        CatPhotoView(photoData: cat.photos.first, size: 40)

                                        VStack(alignment: .leading, spacing: CatchSpacing.space2) {
                                            Text(cat.displayName)
                                                .font(.body.weight(.semibold))
                                                .foregroundStyle(cat.isUnnamed ? CatchTheme.textSecondary : CatchTheme.textPrimary)

                                            if !cat.location.name.isEmpty {
                                                Text(cat.location.name)
                                                    .font(.caption)
                                                    .foregroundStyle(CatchTheme.textSecondary)
                                            }
                                        }
                                    }
                                } else {
                                    Text(CatchStrings.Log.pickACat)
                                        .foregroundStyle(CatchTheme.textSecondary)
                                }
                            }
                        }
                    }
                }

                Section(CatchStrings.Log.encounterDetails) {
                    DatePicker(
                        CatchStrings.Common.date,
                        selection: $date,
                        in: EncounterDateValidator.allowedRange,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    LocationPickerView(location: $location)
                }

                Section(CatchStrings.Common.photos) {
                    PhotoPickerView(selectedPhotos: $photos)
                }

                Section(CatchStrings.Common.notes) {
                    LimitedTextFieldView(
                        CatchStrings.Log.whatHappened,
                        text: $notes,
                        limit: TextInputLimits.encounterNotes
                    )
                }
            }
            .navigationTitle(CatchStrings.Log.logEncounterTitle)
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
                            .disabled(selectedCat == nil)
                            .fontWeight(.semibold)
                    }
                }
            }
            .disabled(isSaving)
            .onAppear {
                if let preselectedCat {
                    selectedCat = preselectedCat
                } else if cats.count == 1 && selectedCat == nil {
                    selectedCat = cats.first
                }
            }
            .sheet(isPresented: $showingAddCat) {
                AddCatView()
            }
        }
    }

    private func save() async {
        guard let cat = selectedCat else { return }
        let encounter = Encounter(
            date: date,
            location: location,
            notes: notes,
            cat: cat,
            photos: photos
        )

        isSaving = true
        defer { isSaving = false }

        do {
            try await encounterSyncService?.syncNewEncounter(encounter, for: cat)
        } catch {
            toastManager.showError(CatchStrings.Toast.encounterSyncFailed)
            return
        }

        modelContext.insert(encounter)
        onSave?()
        dismiss()
    }
}
