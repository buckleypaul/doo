import Foundation

public enum CLIError: LocalizedError, Equatable {
    case taskNotFound(String)
    case ambiguousTaskID(String, Int)
    case emptyTitle
    case invalidPriority(Int)
    case invalidStatus(String)

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
        case .invalidStatus(let s):
            return "Invalid status '\(s)'. Valid: untriaged, backlog, inprogress, inreview"
        }
    }
}
