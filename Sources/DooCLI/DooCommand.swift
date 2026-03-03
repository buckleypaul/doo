import ArgumentParser
import DooCLILib

@main
struct DooCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "doo",
        abstract: "Command-line task manager",
        subcommands: [TaskCommand.self],
        defaultSubcommand: TaskCommand.self
    )
}
