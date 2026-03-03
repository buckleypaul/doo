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

    func run() throws {
        let store = CLITaskStore()
        let tasks = done ? store.loadCompletedTasks() : store.loadActiveTasks()

        let filter = buildFilterState()
        let filtered = filter.apply(to: tasks)

        if json {
            print(try JSONOutput.encode(filtered))
        } else {
            print(TableFormatter.formatTaskList(filtered))
        }
    }

    private func buildFilterState() -> FilterState {
        var minP = minPriority ?? 1
        var maxP = maxPriority ?? 5
        if let p = priority {
            minP = p
            maxP = p
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

        return FilterState(
            searchText: search ?? "",
            sortOption: sortOption,
            selectedTags: Set(tag),
            minPriority: minP,
            maxPriority: maxP,
            overdueOnly: overdue
        )
    }
}
