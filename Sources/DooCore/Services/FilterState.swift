import Foundation

public enum SortOption: String, CaseIterable, Identifiable, Sendable {
    case priority = "Priority"
    case dateAddedNewest = "Newest"
    case dateAddedOldest = "Oldest"
    case dueDateSoonest = "Due Soonest"
    case alphabetical = "A-Z"
    case dateCompleted = "Date Completed"

    public var id: String { rawValue }
}

public struct FilterState: Sendable {
    public var searchText = ""
    public var sortOption: SortOption = .priority
    public var selectedTags: Set<String> = []
    public var selectedPriorities: Set<Int> = []
    public var overdueOnly = false

    public init(
        searchText: String = "",
        sortOption: SortOption = .priority,
        selectedTags: Set<String> = [],
        selectedPriorities: Set<Int> = [],
        overdueOnly: Bool = false
    ) {
        self.searchText = searchText
        self.sortOption = sortOption
        self.selectedTags = selectedTags
        self.selectedPriorities = selectedPriorities
        self.overdueOnly = overdueOnly
    }
}

extension FilterState {
    public func apply(to tasks: [DooTask]) -> [DooTask] {
        var result = tasks

        // Search
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { task in
                task.title.lowercased().contains(query)
                || (task.description?.lowercased().contains(query) ?? false)
                || (task.notes?.lowercased().contains(query) ?? false)
                || task.tags.contains { $0.lowercased().contains(query) }
            }
        }

        // Tag filter
        if !selectedTags.isEmpty {
            result = result.filter { task in
                !selectedTags.isDisjoint(with: task.tags)
            }
        }

        // Priority filter
        if !selectedPriorities.isEmpty {
            result = result.filter { selectedPriorities.contains($0.priority) }
        }

        // Overdue filter
        if overdueOnly {
            result = result.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return DateFormatting.isOverdue(dueDate)
            }
        }

        // Sort
        result.sort { a, b in
            switch sortOption {
            case .priority:
                return a.priority < b.priority
            case .dateAddedNewest:
                return a.dateAdded > b.dateAdded
            case .dateAddedOldest:
                return a.dateAdded < b.dateAdded
            case .dueDateSoonest:
                let aDate = a.dueDate ?? .distantFuture
                let bDate = b.dueDate ?? .distantFuture
                return aDate < bDate
            case .alphabetical:
                return a.title.localizedCompare(b.title) == .orderedAscending
            case .dateCompleted:
                let aDate = a.dateCompleted ?? .distantPast
                let bDate = b.dateCompleted ?? .distantPast
                return aDate > bDate
            }
        }

        return result
    }
}
