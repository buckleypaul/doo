import ArgumentParser

struct SubtaskCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "subtask",
        abstract: "Manage subtasks",
        subcommands: [
            SubtaskAddCommand.self,
            SubtaskCompleteCommand.self,
            SubtaskDeleteCommand.self,
        ]
    )
}
