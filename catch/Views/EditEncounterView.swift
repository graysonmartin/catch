import SwiftUI

struct EditEncounterView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppleAuthService.self) private var authService: AppleAuthService?
    @Environment(CKCatSyncService.self) private var catSyncService: CKCatSyncService?
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
        syncToCloud()
        dismiss()
    }

    private func syncToCloud() {
        guard let userID = authService?.authState.user?.userIdentifier,
              let syncService = catSyncService,
              let encRecordName = encounter.cloudKitRecordName,
              let catRecordName = encounter.cat?.cloudKitRecordName else { return }

        let payload = EncounterSyncPayload(
            recordName: encRecordName,
            catRecordName: catRecordName,
            date: encounter.date,
            locationName: encounter.location.name,
            locationLatitude: encounter.location.latitude,
            locationLongitude: encounter.location.longitude,
            notes: encounter.notes,
            photos: encounter.photos
        )

        Task {
            _ = try? await syncService.saveEncounter(payload, ownerID: userID)
        }
    }
}
