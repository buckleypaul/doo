import ArgumentParser
import DooCore
import Foundation

struct TaskUncompleteCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "uncomplete",
        abstract: "Restore a completed task to active"
    )

    @Argument(help: "Task ID (row number or UUID prefix from done list)")
    var id: String

    func run() throws {
        let store = CLITaskStore()
        let done = store.loadCompletedTasks()
        let task = try TaskIDResolver.resolve(id, in: done)

        try store.uncompleteTask(task)
        print("Restored: \(task.title)")
    }
}
