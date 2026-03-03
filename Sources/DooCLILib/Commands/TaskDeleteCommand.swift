import ArgumentParser
import DooCore
import Foundation

struct TaskDeleteCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a task"
    )

    @Argument(help: "Task ID (row number or UUID prefix)")
    var id: String

    func run() throws {
        let store = CLITaskStore()
        let allTasks = store.loadActiveTasks() + store.loadCompletedTasks()
        let task = try TaskIDResolver.resolve(id, in: allTasks)

        try store.deleteTask(task)
        print("Deleted: \(task.title)")
    }
}
