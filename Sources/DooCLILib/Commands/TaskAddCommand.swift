import ArgumentParser
import DooCore
import Foundation

struct TaskAddCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "add",
        abstract: "Add a new task"
    )

    @Argument(help: "Task title (supports inline syntax: \"title !N #tag @date /description\")")
    var input: String

    @Option(name: .long, help: "Priority (0-2)")
    var priority: Int?

    @Option(name: .long, help: "Tag (repeatable)", transform: { $0.lowercased() })
    var tag: [String] = []

    @Option(name: .long, help: "Due date (today, tomorrow, or yyyy-MM-dd)")
    var due: String?

    @Option(name: .long, help: "Description text")
    var description: String?

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
        if let desc = description {
            task.description = desc
        }

        let store = CLITaskStore()
        try store.addTask(task)

        print("Added: \(task.title) (!\(task.priority))")
    }
}
