import SwiftUI

struct EditEncounterView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CKEncounterSyncService.self) private var encounterSyncService: CKEncounterSyncService?
    @Bindable var encounter: Encounter

    @State private var date: Date
    @State private var location: Location
    @State private var notes: String
    @State private var photos: [Data]

    init(encounter: Encounter) {
        self.encounter = encounter
        _date = State(initialValue: encounter.date)
        _location = State(initialValue: encounter.location)
        _notes = State(initialValue: encounter.notes)
        _photos = State(initialValue: encounter.photos)
    }

    var body: some View {
        NavigationStack {
            Form {
                if let cat = encounter.cat {
                    Section(CatchStrings.Log.catSection) {
                        HStack(spacing: CatchSpacing.space12) {
                            CatPhotoView(photoData: cat.photos.first, size: 40)
                            Text(cat.name)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(CatchTheme.textPrimary)
                            Spacer()
                        }
                    }
                }

                Section(CatchStrings.Log.detailsSection) {
                    DatePicker(CatchStrings.Common.date, selection: $date, displayedComponents: [.date, .hourAndMinute])
                    LocationPickerView(location: $location)
                }

                Section(CatchStrings.Log.photosSection) {
                    PhotoPickerView(selectedPhotos: $photos)
                }

                Section(CatchStrings.Log.notesSection) {
                    TextField(CatchStrings.Log.whatHappenedLower, text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(CatchStrings.Log.editEncounterTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(CatchStrings.Common.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(CatchStrings.Common.save) { save() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func save() {
        encounter.date = date
        encounter.location = location
        encounter.notes = notes
        encounter.photos = photos
        Task { await encounterSyncService?.syncEncounterUpdate(encounter) }
        dismiss()
    }
}
