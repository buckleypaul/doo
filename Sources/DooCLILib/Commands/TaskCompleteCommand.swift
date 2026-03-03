import ArgumentParser
import DooCore
import Foundation

struct TaskCompleteCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "complete",
        abstract: "Mark a task as complete"
    )

    @Argument(help: "Task ID (row number or UUID prefix)")
    var id: String

    func run() throws {
        let store = CLITaskStore()
        let active = store.loadActiveTasks()
        let task = try TaskIDResolver.resolve(id, in: active)

        try store.completeTask(task)
        print("Completed: \(task.title)")
    }
}
