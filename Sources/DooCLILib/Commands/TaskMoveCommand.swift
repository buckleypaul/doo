import ArgumentParser
import DooCore
import Foundation

struct TaskMoveCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "move",
        abstract: "Move a task to a pipeline status"
    )

    @Argument(help: "Task ID (row number or UUID prefix)")
    var id: String

    @Argument(help: "Target status (triage, backlog, inprogress, inreview)")
    var status: String

    func run() throws {
        guard let newStatus = PipelineStatus.fromShorthand(status) else {
            throw CLIError.invalidStatus(status)
        }

        let store = CLITaskStore()
        let allTasks = store.loadActiveTasks() + store.loadCompletedTasks()
        var task = try TaskIDResolver.resolve(id, in: allTasks)
        task.status = newStatus
        try store.updateTask(task)
        print("Moved '\(task.title)' to \(newStatus.displayName)")
    }
}
