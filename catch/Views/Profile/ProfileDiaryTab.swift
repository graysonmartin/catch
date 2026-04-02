import SwiftUI
import CatchCore

struct ProfileDiaryTab: View {
    let encounters: [Encounter]

    @Environment(SupabaseSocialInteractionService.self) private var socialService: SupabaseSocialInteractionService?
    @Environment(ToastManager.self) private var toastManager

    @State private var selectedEncounterDetail: EncounterDetailData?

    private var groupedEncounters: [(date: Date, encounters: [Encounter])] {
        let grouped = Dictionary(grouping: encounters) { encounter in
            Calendar.current.startOfDay(for: encounter.date)
        }
        return grouped
            .sorted { $0.key > $1.key }
            .map { (date: $0.key, encounters: $0.value.sorted { $0.date > $1.date }) }
    }

    private var earliestEncounterIDs: Set<UUID> {
        var ids = Set<UUID>()
        var seenCats = Set<UUID>()
        let allSorted = encounters.sorted { $0.date < $1.date }
        for encounter in allSorted {
            if let catID = encounter.catID, !seenCats.contains(catID) {
                seenCats.insert(catID)
                ids.insert(encounter.id)
            }
        }
        return ids
    }

    private var isShowingDetail: Binding<Bool> {
        Binding(
            get: { selectedEncounterDetail != nil },
            set: { if !$0 { selectedEncounterDetail = nil } }
        )
    }

    var body: some View {
        if encounters.isEmpty {
            EmptyStateView(
                icon: "book.closed",
                title: CatchStrings.Diary.emptyTitle,
                subtitle: CatchStrings.Diary.emptySubtitle
            )
        } else {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(groupedEncounters, id: \.date) { group in
                    Section {
                        ForEach(group.encounters) { encounter in
                            diaryRow(for: encounter)
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
            .task {
                await loadInteractionData()
            }
            .sheet(isPresented: isShowingDetail) {
                if let detail = selectedEncounterDetail {
                    EncounterDetailSheet(data: detail)
                }
            }
        }
    }

    // MARK: - Row Builder

    @ViewBuilder
    private func diaryRow(for encounter: Encounter) -> some View {
        let recordName = encounter.id.uuidString
        let likes = likeCount(for: recordName)
        let comments = commentCount(for: recordName)
        let isFirst = earliestEncounterIDs.contains(encounter.id)

        if encounter.cat != nil {
            Button {
                selectedEncounterDetail = EncounterDetailData(
                    local: encounter,
                    isFirstEncounter: isFirst
                )
            } label: {
                DiaryEntryRow(
                    encounter: encounter,
                    isFirstEncounter: isFirst,
                    likeCount: likes,
                    commentCount: comments
                )
            }
            .buttonStyle(.plain)
        } else {
            DiaryEntryRow(
                encounter: encounter,
                isFirstEncounter: false,
                likeCount: likes,
                commentCount: comments
            )
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

    private func likeCount(for recordName: String?) -> Int {
        guard let recordName else { return 0 }
        return socialService?.likeCount(for: recordName) ?? 0
    }

    private func commentCount(for recordName: String?) -> Int {
        guard let recordName else { return 0 }
        return socialService?.commentCount(for: recordName) ?? 0
    }

    private func loadInteractionData() async {
        guard let socialService else { return }
        let recordNames = encounters.map { $0.id.uuidString }
        guard !recordNames.isEmpty else { return }
        do {
            try await socialService.loadInteractionData(for: recordNames)
        } catch where error.isCancellation {
        } catch {
            toastManager.showError(CatchStrings.Toast.feedLoadFailed)
        }
    }
}
