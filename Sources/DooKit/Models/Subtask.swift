import Foundation

public struct Subtask: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var completed: Bool

    public init(id: UUID = UUID(), title: String, completed: Bool = false) {
        self.id = id
        self.title = title
        self.completed = completed
    }
}
