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
                Section("Which cat?") {
                    if cats.isEmpty {
                        Text("No cats registered yet. Add a new cat first.")
                            .foregroundStyle(CatchTheme.textSecondary)
                    } else {
                        Picker("Cat", selection: $selectedCat) {
                            Text("Select a cat").tag(nil as Cat?)
                            ForEach(cats) { cat in
                                Text(cat.name).tag(cat as Cat?)
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
