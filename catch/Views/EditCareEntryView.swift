import SwiftUI

struct EditCareEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var entry: CareEntry

    @State private var startDate: Date
    @State private var endDate: Date
    @State private var notes: String

    init(entry: CareEntry) {
        self.entry = entry
        _startDate = State(initialValue: entry.startDate)
        _endDate = State(initialValue: entry.endDate)
        _notes = State(initialValue: entry.notes)
    }

    private var durationDays: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }

    private var durationLabel: String {
        switch durationDays {
        case 0: return "same day"
        case 1: return "1 day"
        default: return "\(durationDays) days"
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                if let cat = entry.cat {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "pawprint.fill")
                                .foregroundStyle(CatchTheme.primary)
                            Text(cat.name)
                                .font(.body.weight(.medium))
                                .foregroundStyle(CatchTheme.textPrimary)
                        }
                    }
                }

                Section("date range") {
                    DatePicker("start", selection: $startDate, displayedComponents: .date)
                        .onChange(of: startDate) { _, newStart in
                            if endDate < newStart {
                                endDate = newStart
                            }
                        }
                    DatePicker("end", selection: $endDate, in: startDate..., displayedComponents: .date)

                    HStack {
                        Image(systemName: "clock")
                            .foregroundStyle(CatchTheme.primary)
                        Text(durationLabel)
                            .font(.subheadline)
                            .foregroundStyle(CatchTheme.textSecondary)
                    }
                }

                Section("notes") {
                    TextField("what care did you provide?", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("edit care entry")
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
        entry.startDate = startDate
        entry.endDate = endDate
        entry.notes = notes
        dismiss()
    }
}
