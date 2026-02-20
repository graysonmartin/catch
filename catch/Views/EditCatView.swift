import SwiftUI

struct EditCatView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppleAuthService.self) private var authService: AppleAuthService?
    @Environment(CKCatSyncService.self) private var catSyncService: CKCatSyncService?
    @Bindable var cat: Cat

    @State private var name: String
    @State private var estimatedAge: String
    @State private var location: Location
    @State private var notes: String
    @State private var isOwned: Bool
    @State private var photos: [Data]

    init(cat: Cat) {
        self.cat = cat
        _name = State(initialValue: cat.name)
        _estimatedAge = State(initialValue: cat.estimatedAge)
        _location = State(initialValue: cat.location)
        _notes = State(initialValue: cat.notes)
        _isOwned = State(initialValue: cat.isOwned)
        _photos = State(initialValue: cat.photos)
    }

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
            }
            .navigationTitle("Edit Cat")
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
        cat.name = name.trimmingCharacters(in: .whitespaces)
        cat.estimatedAge = estimatedAge
        cat.location = location
        cat.notes = notes
        cat.isOwned = isOwned
        cat.photos = photos
        syncToCloud()
        dismiss()
    }

    private func syncToCloud() {
        guard let userID = authService?.authState.user?.userIdentifier,
              let syncService = catSyncService,
              cat.cloudKitRecordName != nil else { return }

        let payload = CatSyncPayload(
            recordName: cat.cloudKitRecordName,
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
            _ = try? await syncService.saveCat(payload, ownerID: userID)
        }
    }
}
