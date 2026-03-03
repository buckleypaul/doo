import Foundation

public enum CLIError: LocalizedError, Equatable {
    case taskNotFound(String)
    case ambiguousTaskID(String, Int)
    case emptyTitle
    case invalidPriority(Int)

    public var errorDescription: String? {
        switch self {
        case .taskNotFound(let id):
            return "No task found matching '\(id)'"
        case .ambiguousTaskID(let id, let count):
            return "Ambiguous task ID '\(id)' matches \(count) tasks"
        case .emptyTitle:
            return "Task title cannot be empty"
        case .invalidPriority(let p):
            return "Priority must be 0, 1, or 2 (got \(p))"
        }
    }
}
