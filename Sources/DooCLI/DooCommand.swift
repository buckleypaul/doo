import ArgumentParser
import DooCore
import DooCLILib

@main
struct DooCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "doo",
        abstract: "Command-line task manager",
        version: dooVersion,
        subcommands: [TaskCommand.self],
        defaultSubcommand: TaskCommand.self
    )
}
