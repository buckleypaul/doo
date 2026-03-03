import ArgumentParser
import DooCore
import Foundation

struct SubtaskCompleteCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "complete",
        abstract: "Mark a subtask as complete"
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
        guard let index = task.subtasks.firstIndex(where: { $0.id == subtask.id }) else {
            throw CLIError.subtaskNotFound(subtaskID)
        }
        task.subtasks[index].completed = true

        try store.updateTask(task)
        print("Completed subtask: \(subtask.title)")
    }
}
