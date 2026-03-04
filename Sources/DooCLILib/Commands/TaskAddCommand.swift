import ArgumentParser
import DooCore
import Foundation

struct TaskAddCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "add",
        abstract: "Add a new task"
    )

    @Argument(help: "Task title (supports inline syntax: \"title !N #tag @date /notes\")")
    var input: String

    @Option(name: .long, help: "Priority (0-2)")
    var priority: Int?

    @Option(name: .long, help: "Tag (repeatable)", transform: { $0.lowercased() })
    var tag: [String] = []

    @Option(name: .long, help: "Due date (today, tomorrow, or yyyy-MM-dd)")
    var due: String?

    @Option(name: .long, help: "Notes text")
    var notes: String?

    @Option(name: .long, help: "Pipeline status (triage, backlog, inprogress, inreview)")
    var status: String?

    func run() throws {
        // Parse inline syntax first
        var task = InlineSyntaxParser.parse(input)

        // Override/merge with explicit flags
        if let p = priority {
            guard (0...2).contains(p) else { throw CLIError.invalidPriority(p) }
            task.priority = p
        }
        if !tag.isEmpty {
            let merged = Set(task.tags + tag)
            task.tags = Array(merged).sorted()
        }
        if let d = due {
            task.dueDate = DueDateParser.parse(d)
        }
        if let n = notes {
            task.notes = n
        }
        if let s = status {
            guard let parsed = PipelineStatus.fromShorthand(s) else {
                throw CLIError.invalidStatus(s)
            }
            task.status = parsed
        }

        let store = CLITaskStore()
        try store.addTask(task)

        print("Added: \(task.title) (!\(task.priority))")
    }
}
