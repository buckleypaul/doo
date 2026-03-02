import Foundation
@testable import DooKit

func dateOnly(_ string: String) -> Date {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter.date(from: string)!
}

func iso8601(_ string: String) -> Date {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.date(from: string)!
}

func sampleTask(
    id: UUID = UUID(),
    title: String = "Test Task",
    description: String? = nil,
    notes: String? = nil,
    priority: Int = 3,
    tags: [String] = [],
    dueDate: Date? = nil,
    dateAdded: Date = Date(),
    dateCompleted: Date? = nil,
    subtasks: [Subtask] = []
) -> DooTask {
    DooTask(
        id: id,
        title: title,
        description: description,
        notes: notes,
        priority: priority,
        tags: tags,
        dueDate: dueDate,
        dateAdded: dateAdded,
        dateCompleted: dateCompleted,
        subtasks: subtasks
    )
}

func writeTaskFile(_ tasks: [DooTask], to url: URL) throws {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let taskFile = TaskFile(tasks: tasks)
    let data = try encoder.encode(taskFile)
    try data.write(to: url)
}
