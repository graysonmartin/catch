import SwiftUI
import SwiftData

struct LogEncounterView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppleAuthService.self) private var authService: AppleAuthService?
    @Environment(CKEncounterRepository.self) private var encounterRepository: CKEncounterRepository?
    @Query(sort: \Cat.name) private var cats: [Cat]

    @State private var selectedCat: Cat?
    @State private var date = Date()
    @State private var location = Location.empty
    @State private var notes = ""
    @State private var photos: [Data] = []
    @State private var showingAddCat = false

    var preselectedCat: Cat? = nil

    var body: some View {
        NavigationStack {
            Form {
                if preselectedCat != nil {
                    Section {
                        if let cat = selectedCat {
                            HStack(spacing: 12) {
                                CatPhotoView(photoData: cat.photos.first, size: 40)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("logging for")
                                        .font(.caption)
                                        .foregroundStyle(CatchTheme.textSecondary)
                                    Text(cat.name)
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(CatchTheme.textPrimary)
                                }
                                Spacer()
                            }
                        }
                    }
                } else {
                    Section("which cat?") {
                        if cats.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("no cats registered yet")
                                    .foregroundStyle(CatchTheme.textSecondary)
                                Button {
                                    showingAddCat = true
                                } label: {
                                    Label("register one now", systemImage: "plus.circle.fill")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(CatchTheme.primary)
                                }
                            }
                        } else {
                            NavigationLink {
                                CatPickerView(cats: cats, selectedCat: $selectedCat)
                            } label: {
                                if let cat = selectedCat {
                                    HStack(spacing: 12) {
                                        CatPhotoView(photoData: cat.photos.first, size: 40)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(cat.name)
                                                .font(.body.weight(.semibold))
                                                .foregroundStyle(CatchTheme.textPrimary)

                                            if !cat.location.name.isEmpty {
                                                Text(cat.location.name)
                                                    .font(.caption)
                                                    .foregroundStyle(CatchTheme.textSecondary)
                                            }
                                        }
                                    }
                                } else {
                                    Text("pick a cat")
                                        .foregroundStyle(CatchTheme.textSecondary)
                                }
                            }
                        }
                    }
                }

                Section("Encounter Details") {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    LocationPickerView(location: $location)
                }

                Section("Photos") {
                    PhotoPickerView(selectedPhotos: $photos)
                }

                Section("Notes") {
                    TextField("What happened?", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Log Encounter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(selectedCat == nil)
                        .fontWeight(.semibold)
                }
            }
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

    private func save() {
        guard let cat = selectedCat else { return }
        let encounter = Encounter(
            date: date,
            location: location,
            notes: notes,
            cat: cat,
            photos: photos
        )
        modelContext.insert(encounter)
        syncToCloud(encounter: encounter, cat: cat)
        dismiss()
    }

    private func syncToCloud(encounter: Encounter, cat: Cat) {
        guard let userID = authService?.authState.user?.userIdentifier,
              let encounterRepository,
              let catRecordName = cat.cloudKitRecordName else { return }

        let payload = EncounterSyncPayload(
            recordName: nil,
            catRecordName: catRecordName,
            date: encounter.date,
            locationName: encounter.location.name,
            locationLatitude: encounter.location.latitude,
            locationLongitude: encounter.location.longitude,
            notes: encounter.notes,
            photos: encounter.photos
        )

        Task {
            if let recordName = try? await encounterRepository.save(payload, ownerID: userID) {
                encounter.cloudKitRecordName = recordName
            }
        }
    }
}
