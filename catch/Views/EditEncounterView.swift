import SwiftUI

struct EditEncounterView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CKCloudSyncService.self) private var cloudSyncService: CKCloudSyncService?
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
                    Section("cat") {
                        HStack(spacing: 12) {
                            CatPhotoView(photoData: cat.photos.first, size: 40)
                            Text(cat.name)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(CatchTheme.textPrimary)
                            Spacer()
                        }
                    }
                }

                Section("details") {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    LocationPickerView(location: $location)
                }

                Section("photos") {
                    PhotoPickerView(selectedPhotos: $photos)
                }

                Section("notes") {
                    TextField("what happened?", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Encounter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
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
        Task { await cloudSyncService?.syncEncounterUpdate(encounter) }
        dismiss()
    }
}
