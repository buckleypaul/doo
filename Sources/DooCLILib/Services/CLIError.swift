import Foundation

public enum CLIError: LocalizedError, Equatable {
    case taskNotFound(String)
    case ambiguousTaskID(String, Int)
    case subtaskNotFound(String)
    case ambiguousSubtaskID(String, Int)
    case emptyTitle

    public var errorDescription: String? {
        switch self {
        case .taskNotFound(let id):
            return "No task found matching '\(id)'"
        case .ambiguousTaskID(let id, let count):
            return "Ambiguous task ID '\(id)' matches \(count) tasks"
        case .subtaskNotFound(let id):
            return "No subtask found matching '\(id)'"
        case .ambiguousSubtaskID(let id, let count):
            return "Ambiguous subtask ID '\(id)' matches \(count) subtasks"
        case .emptyTitle:
            return "Task title cannot be empty"
        }
    }
}
