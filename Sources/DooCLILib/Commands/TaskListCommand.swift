import ArgumentParser
import DooCore
import Foundation

struct TaskListCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List tasks"
    )

    @Flag(name: .long, help: "Show completed tasks")
    var done = false

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    @Option(name: .long, help: "Filter by tag (repeatable)", transform: { $0.lowercased() })
    var tag: [String] = []

    @Option(name: .long, help: "Filter by exact priority")
    var priority: Int?

    @Option(name: .long, help: "Minimum priority (1=highest)")
    var minPriority: Int?

    @Option(name: .long, help: "Maximum priority (5=lowest)")
    var maxPriority: Int?

    @Flag(name: .long, help: "Show only overdue tasks")
    var overdue = false

    @Option(name: .long, help: "Search text (title, description, notes, tags)")
    var search: String?

    @Option(name: .long, help: "Sort order: priority, newest, oldest, due, alpha, completed")
    var sort: String?

    @Option(name: .long, help: "Filter by status (repeatable: untriaged, backlog, inprogress, inreview)")
    var status: [String] = []

    func run() throws {
        let store = CLITaskStore()
        let tasks = done ? store.loadCompletedTasks() : store.loadActiveTasks()

        let filter = try buildFilterState()
        let filtered = filter.apply(to: tasks)

        if json {
            print(try JSONOutput.encode(filtered))
        } else if !done && status.isEmpty && filter.selectedStatuses.isEmpty {
            print(TableFormatter.formatGroupedTaskList(filtered))
        } else {
            print(TableFormatter.formatTaskList(filtered))
        }
    }

    func buildFilterState() throws -> FilterState {
        var selectedPriorities: Set<Int> = []
        if let p = priority {
            guard (1...5).contains(p) else {
                throw ValidationError("--priority (\(p)) must be between 1 and 5")
            }
            selectedPriorities = [p]
        } else {
            if let minP = minPriority {
                guard (1...5).contains(minP) else {
                    throw ValidationError("--min-priority (\(minP)) must be between 1 and 5")
                }
            }
            if let maxP = maxPriority {
                guard (1...5).contains(maxP) else {
                    throw ValidationError("--max-priority (\(maxP)) must be between 1 and 5")
                }
            }
            if let minP = minPriority, let maxP = maxPriority {
                if minP <= maxP {
                    selectedPriorities = Set(minP...maxP)
                } else {
                    throw ValidationError("--min-priority (\(minP)) must be ≤ --max-priority (\(maxP))")
                }
            } else if let minP = minPriority {
                selectedPriorities = Set(minP...5)
            } else if let maxP = maxPriority {
                selectedPriorities = Set(1...maxP)
            }
        }

        let sortOption: SortOption
        switch sort?.lowercased() {
        case "priority", nil:
            sortOption = done ? .dateCompleted : .priority
        case "newest":
            sortOption = .dateAddedNewest
        case "oldest":
            sortOption = .dateAddedOldest
        case "due":
            sortOption = .dueDateSoonest
        case "alpha":
            sortOption = .alphabetical
        case "completed":
            sortOption = .dateCompleted
        default:
            sortOption = .priority
        }

        var selectedStatuses: Set<PipelineStatus> = []
        for s in status {
            guard let parsed = PipelineStatus.fromShorthand(s) else {
                throw CLIError.invalidStatus(s)
            }
            selectedStatuses.insert(parsed)
        }

        return FilterState(
            searchText: search ?? "",
            sortOption: sortOption,
            selectedTags: Set(tag),
            selectedPriorities: selectedPriorities,
            overdueOnly: overdue,
            selectedStatuses: selectedStatuses
        )
    }
}
