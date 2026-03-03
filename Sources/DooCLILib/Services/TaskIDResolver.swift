import Foundation
import DooCore

public enum TaskIDResolver {
    /// Resolve a user-provided ID (row number or UUID prefix) to a task.
    public static func resolve(_ input: String, in tasks: [DooTask]) throws -> DooTask {
        // Pure integer? -> 1-based row number
        if let rowNumber = Int(input) {
            let index = rowNumber - 1
            guard index >= 0 && index < tasks.count else {
                throw CLIError.taskNotFound(input)
            }
            return tasks[index]
        }

        // Otherwise -> case-insensitive UUID prefix match
        let prefix = input.lowercased()
        let matches = tasks.filter {
            $0.id.uuidString.lowercased().hasPrefix(prefix)
        }

        switch matches.count {
        case 0:
            throw CLIError.taskNotFound(input)
        case 1:
            return matches[0]
        default:
            throw CLIError.ambiguousTaskID(input, matches.count)
        }
    }
}
