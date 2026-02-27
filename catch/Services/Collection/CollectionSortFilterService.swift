import Foundation

/// Data needed to sort and filter a single cat in the collection.
struct CollectionCatItem {
    let id: String
    let name: String
    let isOwned: Bool
    let createdAt: Date
    let encounterCount: Int
    let lastEncounterDate: Date?
}

// MARK: - Protocol

protocol CollectionSortFilterService {
    func apply(
        sort: CollectionSortOption,
        filters: Set<CollectionFilter>,
        to items: [CollectionCatItem],
        now: Date
    ) -> [CollectionCatItem]

    func filter(
        _ items: [CollectionCatItem],
        by filters: Set<CollectionFilter>,
        now: Date
    ) -> [CollectionCatItem]

    func sort(
        _ items: [CollectionCatItem],
        by option: CollectionSortOption
    ) -> [CollectionCatItem]
}

// MARK: - Default Implementation

struct DefaultCollectionSortFilterService: CollectionSortFilterService {

    func apply(
        sort: CollectionSortOption,
        filters: Set<CollectionFilter>,
        to items: [CollectionCatItem],
        now: Date = Date()
    ) -> [CollectionCatItem] {
        let filtered = filter(items, by: filters, now: now)
        return self.sort(filtered, by: sort)
    }

    func filter(
        _ items: [CollectionCatItem],
        by filters: Set<CollectionFilter>,
        now: Date
    ) -> [CollectionCatItem] {
        guard !filters.isEmpty else { return items }

        return items.filter { item in
            for activeFilter in filters {
                if !matches(item: item, filter: activeFilter, now: now) {
                    return false
                }
            }
            return true
        }
    }

    func sort(
        _ items: [CollectionCatItem],
        by option: CollectionSortOption
    ) -> [CollectionCatItem] {
        switch option {
        case .mostRecent:
            return items.sorted {
                ($0.lastEncounterDate ?? .distantPast) > ($1.lastEncounterDate ?? .distantPast)
            }
        case .mostEncounters:
            return items.sorted { $0.encounterCount > $1.encounterCount }
        case .oldestFirst:
            return items.sorted {
                ($0.lastEncounterDate ?? .distantFuture) < ($1.lastEncounterDate ?? .distantFuture)
            }
        case .alphabetical:
            return items.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        }
    }

    // MARK: - Private

    private func matches(item: CollectionCatItem, filter: CollectionFilter, now: Date) -> Bool {
        switch filter {
        case .ownedOnly:
            return item.isOwned
        case .repeats:
            return item.encounterCount > 1
        case .seenLast7Days:
            return isWithinDays(7, lastSeen: item.lastEncounterDate, now: now)
        case .seenLast30Days:
            return isWithinDays(30, lastSeen: item.lastEncounterDate, now: now)
        }
    }

    private func isWithinDays(_ days: Int, lastSeen: Date?, now: Date) -> Bool {
        guard let lastSeen else { return false }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: now) ?? now
        return lastSeen >= cutoff
    }
}
