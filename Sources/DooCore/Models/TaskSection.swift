import Foundation

public struct TaskSection: Codable, Identifiable, Sendable, Equatable {
    public var id: UUID
    public var name: String
    public var order: Int
    public var isCollapsed: Bool

    // Filter fields
    public var searchText: String
    public var selectedTags: Set<String>
    public var selectedPriorities: Set<Int>
    public var selectedStatuses: Set<PipelineStatus>
    public var overdueOnly: Bool

    // Sort fields
    public var sortColumn: String
    public var sortAscending: Bool

    public init(
        id: UUID = UUID(),
        name: String = "All Tasks",
        order: Int = 0,
        isCollapsed: Bool = false,
        searchText: String = "",
        selectedTags: Set<String> = [],
        selectedPriorities: Set<Int> = [],
        selectedStatuses: Set<PipelineStatus> = [],
        overdueOnly: Bool = false,
        sortColumn: String = "priority",
        sortAscending: Bool = true
    ) {
        self.id = id
        self.name = name
        self.order = order
        self.isCollapsed = isCollapsed
        self.searchText = searchText
        self.selectedTags = selectedTags
        self.selectedPriorities = selectedPriorities
        self.selectedStatuses = selectedStatuses
        self.overdueOnly = overdueOnly
        self.sortColumn = sortColumn
        self.sortAscending = sortAscending
    }

    public static var defaultSection: TaskSection {
        TaskSection()
    }

    public func toFilterState() -> FilterState {
        let sortOption: SortOption = switch sortColumn {
        case "title": .alphabetical
        case "dueDate": .dueDateSoonest
        case "dateAdded": sortAscending ? .dateAddedOldest : .dateAddedNewest
        default: .priority
        }

        return FilterState(
            searchText: searchText,
            sortOption: sortOption,
            selectedTags: selectedTags,
            selectedPriorities: selectedPriorities,
            overdueOnly: overdueOnly,
            selectedStatuses: selectedStatuses
        )
    }
}
