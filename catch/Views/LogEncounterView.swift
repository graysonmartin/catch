import SwiftUI
import SwiftData

struct LogEncounterView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Cat.name) private var cats: [Cat]

    @State private var selectedCat: Cat?
    @State private var date = Date()
    @State private var location = Location.empty
    @State private var notes = ""
    @State private var photos: [Data] = []

    var body: some View {
        NavigationStack {
            Form {
                Section("which cat?") {
                    if cats.isEmpty {
                        Text("no cats registered yet. add one first.")
                            .foregroundStyle(CatchTheme.textSecondary)
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
                if cats.count == 1 && selectedCat == nil {
                    selectedCat = cats.first
                }
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
        dismiss()
    }
}
