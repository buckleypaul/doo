import ArgumentParser

public struct TaskCommand: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "task",
        abstract: "Manage tasks",
        subcommands: [
            TaskAddCommand.self,
            TaskListCommand.self,
            TaskShowCommand.self,
            TaskCompleteCommand.self,
            TaskUncompleteCommand.self,
            TaskEditCommand.self,
            TaskDeleteCommand.self,
        ]
    )

    public init() {}
}
