import ArgumentParser
import DooCore
import Foundation

struct SubtaskDeleteCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a subtask"
    )

    @Argument(help: "Parent task ID (row number or UUID prefix)")
    var taskID: String

    @Argument(help: "Subtask ID (row number or UUID prefix)")
    var subtaskID: String

    func run() throws {
        let store = CLITaskStore()
        let active = store.loadActiveTasks()
        var task = try TaskIDResolver.resolve(taskID, in: active)

        let subtask = try TaskIDResolver.resolveSubtask(subtaskID, in: task)
        task.subtasks.removeAll { $0.id == subtask.id }

        try store.updateTask(task)
        print("Deleted subtask: \(subtask.title)")
    }
}
