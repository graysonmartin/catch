import SwiftUI
import SwiftData
import CatchCore

struct ProfileDiaryTab: View {
    let encounters: [Encounter]
    let searchText: String

    private var filteredEncounters: [Encounter] {
        guard !searchText.isEmpty else { return encounters }
        return encounters.filter { encounter in
            encounter.cat?.displayName.localizedCaseInsensitiveContains(searchText) == true
            || encounter.notes.localizedCaseInsensitiveContains(searchText)
            || encounter.location.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var groupedEncounters: [(date: Date, encounters: [Encounter])] {
        let grouped = Dictionary(grouping: filteredEncounters) { encounter in
            Calendar.current.startOfDay(for: encounter.date)
        }
        return grouped
            .sorted { $0.key > $1.key }
            .map { (date: $0.key, encounters: $0.value.sorted { $0.date > $1.date }) }
    }

    private var earliestEncounterIDs: Set<PersistentIdentifier> {
        var ids = Set<PersistentIdentifier>()
        var seenCats = Set<PersistentIdentifier>()
        let allSorted = encounters.sorted { $0.date < $1.date }
        for encounter in allSorted {
            if let catID = encounter.cat?.persistentModelID, !seenCats.contains(catID) {
                seenCats.insert(catID)
                ids.insert(encounter.persistentModelID)
            }
        }
        return ids
    }

    var body: some View {
        if encounters.isEmpty {
            EmptyStateView(
                icon: "book.closed",
                title: CatchStrings.Diary.emptyTitle,
                subtitle: CatchStrings.Diary.emptySubtitle
            )
        } else if filteredEncounters.isEmpty {
            EmptyStateView(
                icon: "magnifyingglass",
                title: CatchStrings.Collection.searchEmptyTitle,
                subtitle: CatchStrings.Diary.searchEmptySubtitle(searchText)
            )
        } else {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(groupedEncounters, id: \.date) { group in
                    Section {
                        ForEach(group.encounters) { encounter in
                            if let cat = encounter.cat {
                                NavigationLink(value: cat) {
                                    DiaryEntryRow(
                                        encounter: encounter,
                                        isFirstEncounter: earliestEncounterIDs.contains(encounter.persistentModelID)
                                    )
                                }
                                .buttonStyle(.plain)
                            } else {
                                DiaryEntryRow(
                                    encounter: encounter,
                                    isFirstEncounter: false
                                )
                            }
                        }
                    } header: {
                        Text(formattedDateHeader(group.date))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CatchTheme.textSecondary)
                            .padding(.top, CatchSpacing.space16)
                            .padding(.bottom, CatchSpacing.space4)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Helpers

    private func formattedDateHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDate(date, equalTo: Date(), toGranularity: .year) {
            return date.formatted(.dateTime.month(.abbreviated).day()).lowercased()
        } else {
            return date.formatted(.dateTime.month(.abbreviated).day().year()).lowercased()
        }
    }
}
