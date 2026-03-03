import ArgumentParser
import DooCore
import Foundation

struct SubtaskAddCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "add",
        abstract: "Add a subtask to a task"
    )

    @Argument(help: "Parent task ID (row number or UUID prefix)")
    var taskID: String

    @Argument(help: "Subtask title")
    var title: String

    func run() throws {
        let store = CLITaskStore()
        let active = store.loadActiveTasks()
        var task = try TaskIDResolver.resolve(taskID, in: active)

        let subtask = Subtask(title: title)
        task.subtasks.append(subtask)

        try store.updateTask(task)
        print("Added subtask: \(title)")
    }
}
