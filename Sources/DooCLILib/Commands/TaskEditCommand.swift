import ArgumentParser
import DooCore
import Foundation

struct TaskEditCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "edit",
        abstract: "Edit a task"
    )

    @Argument(help: "Task ID (row number or UUID prefix)")
    var id: String

    @Option(name: .long, help: "New title")
    var title: String?

    @Option(name: .long, help: "New priority (0-2)")
    var priority: Int?

    @Option(name: .long, help: "Add tag (repeatable)", transform: { $0.lowercased() })
    var tag: [String] = []

    @Option(name: .long, help: "Remove tag (repeatable)", transform: { $0.lowercased() })
    var removeTag: [String] = []

    @Option(name: .long, help: "Set due date (today, tomorrow, yyyy-MM-dd, or 'none' to clear)")
    var due: String?

    @Option(name: .long, help: "Set description (or 'none' to clear)")
    var description: String?

    @Option(name: .long, help: "Set notes (or 'none' to clear)")
    var notes: String?

    @Option(name: .long, help: "Pipeline status (triage, backlog, inprogress, inreview)")
    var status: String?

    func run() throws {
        let store = CLITaskStore()
        let allTasks = store.loadActiveTasks() + store.loadCompletedTasks()
        var task = try TaskIDResolver.resolve(id, in: allTasks)

        if let t = title {
            task.title = t
        }
        if let p = priority {
            guard (0...2).contains(p) else { throw CLIError.invalidPriority(p) }
            task.priority = p
        }
        if !tag.isEmpty {
            let merged = Set(task.tags + tag)
            task.tags = Array(merged).sorted()
        }
        if !removeTag.isEmpty {
            task.tags = task.tags.filter { !removeTag.contains($0) }
        }
        if let d = due {
            task.dueDate = d.lowercased() == "none" ? nil : DueDateParser.parse(d)
        }
        if let desc = description {
            task.description = desc.lowercased() == "none" ? nil : desc
        }
        if let n = notes {
            task.notes = n.lowercased() == "none" ? nil : n
        }
        if let s = status {
            guard let parsed = PipelineStatus.fromShorthand(s) else {
                throw CLIError.invalidStatus(s)
            }
            task.status = parsed
        }

        try store.updateTask(task)
        print("Updated: \(task.title)")
    }
}
