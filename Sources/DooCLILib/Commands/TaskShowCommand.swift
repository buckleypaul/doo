import ArgumentParser
import DooCore
import Foundation

struct TaskShowCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "show",
        abstract: "Show task details"
    )

    @Argument(help: "Task ID (row number or UUID prefix)")
    var id: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let store = CLITaskStore()
        let allTasks = store.loadActiveTasks() + store.loadCompletedTasks()
        let task = try TaskIDResolver.resolve(id, in: allTasks)

        if json {
            print(try JSONOutput.encode(task))
        } else {
            print(TableFormatter.formatTaskDetail(task))
        }
    }
}
