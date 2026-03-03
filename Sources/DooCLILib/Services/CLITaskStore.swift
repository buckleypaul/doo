import Foundation
import DooCore

public struct CLITaskStore {
    private let todoURL: URL
    private let doneURL: URL

    public init(configURL: URL? = nil) {
        let config = SettingsReader.load(from: configURL)
        self.todoURL = URL(fileURLWithPath: config.todoFilePath)
        self.doneURL = URL(fileURLWithPath: config.doneFilePath)
    }

    public init(todoPath: String, donePath: String) {
        self.todoURL = URL(fileURLWithPath: todoPath)
        self.doneURL = URL(fileURLWithPath: donePath)
    }

    // MARK: - Read

    public func loadActiveTasks() -> [DooTask] {
        TaskFileIO.loadTasks(from: todoURL)
    }

    public func loadCompletedTasks() -> [DooTask] {
        TaskFileIO.loadTasks(from: doneURL)
    }

    // MARK: - Write

    public func addTask(_ task: DooTask) throws {
        var tasks = loadActiveTasks()
        tasks.insert(task, at: 0)
        try TaskFileIO.saveTasks(tasks, to: todoURL)
    }

    public func completeTask(_ task: DooTask) throws {
        var active = loadActiveTasks()
        guard let index = active.firstIndex(where: { $0.id == task.id }) else {
            throw CLIError.taskNotFound(task.id.uuidString)
        }
        var completed = active.remove(at: index)
        completed.dateCompleted = Date()
        var done = loadCompletedTasks()
        done.insert(completed, at: 0)
        try TaskFileIO.saveTasks(active, to: todoURL)
        try TaskFileIO.saveTasks(done, to: doneURL)
    }

    public func uncompleteTask(_ task: DooTask) throws {
        var done = loadCompletedTasks()
        guard let index = done.firstIndex(where: { $0.id == task.id }) else {
            throw CLIError.taskNotFound(task.id.uuidString)
        }
        var restored = done.remove(at: index)
        restored.dateCompleted = nil
        var active = loadActiveTasks()
        active.insert(restored, at: 0)
        try TaskFileIO.saveTasks(active, to: todoURL)
        try TaskFileIO.saveTasks(done, to: doneURL)
    }

    public func updateTask(_ task: DooTask) throws {
        var active = loadActiveTasks()
        if let index = active.firstIndex(where: { $0.id == task.id }) {
            active[index] = task
            try TaskFileIO.saveTasks(active, to: todoURL)
            return
        }
        var done = loadCompletedTasks()
        if let index = done.firstIndex(where: { $0.id == task.id }) {
            done[index] = task
            try TaskFileIO.saveTasks(done, to: doneURL)
            return
        }
        throw CLIError.taskNotFound(task.id.uuidString)
    }

    public func deleteTask(_ task: DooTask) throws {
        var active = loadActiveTasks()
        if let index = active.firstIndex(where: { $0.id == task.id }) {
            active.remove(at: index)
            try TaskFileIO.saveTasks(active, to: todoURL)
            return
        }
        var done = loadCompletedTasks()
        if let index = done.firstIndex(where: { $0.id == task.id }) {
            done.remove(at: index)
            try TaskFileIO.saveTasks(done, to: doneURL)
            return
        }
        throw CLIError.taskNotFound(task.id.uuidString)
    }
}
