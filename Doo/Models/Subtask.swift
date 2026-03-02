import Foundation

struct Subtask: Codable, Identifiable, Equatable {
    var id: UUID
    var title: String
    var completed: Bool

    init(id: UUID = UUID(), title: String, completed: Bool = false) {
        self.id = id
        self.title = title
        self.completed = completed
    }
}
