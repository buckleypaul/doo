import Foundation

public enum TaskFileIO {
    public static func loadTasks(from url: URL) -> [DooTask] {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let taskFile = try decoder.decode(TaskFile.self, from: data)
            return taskFile.tasks
        } catch {
            print("Failed to load \(url.lastPathComponent): \(error)")
            return []
        }
    }

    public static func saveTasks(_ tasks: [DooTask], to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let taskFile = TaskFile(tasks: tasks)
        let data = try encoder.encode(taskFile)

        let dir = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        // Atomic write: write to temp file then rename
        let tempURL = dir.appendingPathComponent(".\(url.lastPathComponent).tmp")
        try data.write(to: tempURL)
        _ = try FileManager.default.replaceItemAt(url, withItemAt: tempURL)
    }
}
