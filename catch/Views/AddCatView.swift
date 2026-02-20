import SwiftUI
import SwiftData

struct AddCatView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppleAuthService.self) private var authService: AppleAuthService?
    @Environment(CKCatSyncService.self) private var catSyncService: CKCatSyncService?

    @State private var name = ""
    @State private var estimatedAge = ""
    @State private var location = Location.empty
    @State private var notes = ""
    @State private var isOwned = false
    @State private var photos: [Data] = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Cat Info") {
                    TextField("Name", text: $name)
                    TextField("Estimated Age", text: $estimatedAge)
                    LocationPickerView(location: $location)
                    Toggle("I own this cat", isOn: $isOwned)
                }

                Section("Photos") {
                    PhotoPickerView(selectedPhotos: $photos)
                }

                Section("Notes") {
                    TextField("Notes about this cat...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("First Encounter") {
                    Text("A first encounter will be logged automatically with today's date and the location above.")
                        .font(.caption)
                        .foregroundStyle(CatchTheme.textSecondary)
                }
            }
            .navigationTitle("New Cat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func save() {
        let cat = Cat(
            name: name.trimmingCharacters(in: .whitespaces),
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

        syncToCloud(cat: cat, encounter: encounter)
        dismiss()
    }

    private func syncToCloud(cat: Cat, encounter: Encounter) {
        guard let userID = authService?.authState.user?.userIdentifier,
              let syncService = catSyncService else { return }

        let catPayload = CatSyncPayload(
            recordName: nil,
            name: cat.name,
            estimatedAge: cat.estimatedAge,
            locationName: cat.location.name,
            locationLatitude: cat.location.latitude,
            locationLongitude: cat.location.longitude,
            notes: cat.notes,
            isOwned: cat.isOwned,
            createdAt: cat.createdAt,
            photos: cat.photos
        )

        Task {
            if let recordName = try? await syncService.saveCat(catPayload, ownerID: userID) {
                cat.cloudKitRecordName = recordName

                let encPayload = EncounterSyncPayload(
                    recordName: nil,
                    catRecordName: recordName,
                    date: encounter.date,
                    locationName: encounter.location.name,
                    locationLatitude: encounter.location.latitude,
                    locationLongitude: encounter.location.longitude,
                    notes: encounter.notes,
                    photos: encounter.photos
                )
                if let encRecord = try? await syncService.saveEncounter(encPayload, ownerID: userID) {
                    encounter.cloudKitRecordName = encRecord
                }
            }
        }
    }
}
