import Foundation
import Observation

@MainActor
@Observable
public class TaskStore {
    public var activeTasks: [DooTask] = []
    public var completedTasks: [DooTask] = []

    private var todoFileURL: URL
    private var doneFileURL: URL
    private var todoWatcherSource: DispatchSourceFileSystemObject?
    private var doneWatcherSource: DispatchSourceFileSystemObject?
    private var debounceWorkItem: DispatchWorkItem?
    private var isSaving = false

    public init(todoPath: String? = nil, donePath: String? = nil) {
        let home = FileManager.default.homeDirectoryForCurrentUser
        self.todoFileURL = URL(fileURLWithPath: todoPath ?? home.appendingPathComponent("doo-todo.json").path)
        self.doneFileURL = URL(fileURLWithPath: donePath ?? home.appendingPathComponent("doo-done.json").path)
        loadAll()
        startWatching()
    }

    // MARK: - CRUD

    public func addTask(_ task: DooTask) {
        activeTasks.insert(task, at: 0)
        saveTodoFile()
    }

    public func completeTask(_ task: DooTask) {
        guard let index = activeTasks.firstIndex(where: { $0.id == task.id }) else { return }
        var completed = activeTasks.remove(at: index)
        completed.dateCompleted = Date()
        completedTasks.insert(completed, at: 0)
        saveTodoFile()
        saveDoneFile()
    }

    public func uncompleteTask(_ task: DooTask) {
        guard let index = completedTasks.firstIndex(where: { $0.id == task.id }) else { return }
        var restored = completedTasks.remove(at: index)
        restored.dateCompleted = nil
        activeTasks.insert(restored, at: 0)
        saveTodoFile()
        saveDoneFile()
    }

    public func updateTask(_ task: DooTask) {
        if let index = activeTasks.firstIndex(where: { $0.id == task.id }) {
            activeTasks[index] = task
            saveTodoFile()
        } else if let index = completedTasks.firstIndex(where: { $0.id == task.id }) {
            completedTasks[index] = task
            saveDoneFile()
        }
    }

    public func deleteTask(_ task: DooTask) {
        if let index = activeTasks.firstIndex(where: { $0.id == task.id }) {
            activeTasks.remove(at: index)
            saveTodoFile()
        } else if let index = completedTasks.firstIndex(where: { $0.id == task.id }) {
            completedTasks.remove(at: index)
            saveDoneFile()
        }
    }

    // MARK: - File Path Updates

    public func updatePaths(todoPath: String, donePath: String) {
        stopWatching()
        todoFileURL = URL(fileURLWithPath: todoPath)
        doneFileURL = URL(fileURLWithPath: donePath)
        loadAll()
        startWatching()
    }

    // MARK: - Lifecycle

    public func shutdown() {
        stopWatching()
        debounceWorkItem?.cancel()
        debounceWorkItem = nil
    }

    // MARK: - File I/O

    private func loadAll() {
        activeTasks = TaskFileIO.loadTasks(from: todoFileURL)
        completedTasks = TaskFileIO.loadTasks(from: doneFileURL)
    }

    private func saveTodoFile() {
        saveTasksAtomically(activeTasks, to: todoFileURL)
    }

    private func saveDoneFile() {
        saveTasksAtomically(completedTasks, to: doneFileURL)
    }

    private func saveTasksAtomically(_ tasks: [DooTask], to url: URL) {
        isSaving = true
        defer {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.isSaving = false
            }
        }

        do {
            try TaskFileIO.saveTasks(tasks, to: url)
        } catch {
            print("Failed to save \(url.lastPathComponent): \(error)")
        }
    }

    // MARK: - File Watching

    private func startWatching() {
        watchFile(at: todoFileURL) { [weak self] in
            self?.activeTasks = TaskFileIO.loadTasks(from: self!.todoFileURL)
        }
        watchFile(at: doneFileURL) { [weak self] in
            self?.completedTasks = TaskFileIO.loadTasks(from: self!.doneFileURL)
        }
    }

    private func watchFile(at url: URL, onChange: @escaping @Sendable @MainActor () -> Void) {
        // Ensure file exists so we can open a descriptor
        if !FileManager.default.fileExists(atPath: url.path) {
            let emptyData = "{\"tasks\":[]}".data(using: .utf8)!
            try? emptyData.write(to: url)
        }

        let fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .rename],
            queue: .main
        )

        source.setEventHandler { [weak self] in
            guard let self, !self.isSaving else { return }
            // Debounce: wait 100ms for rapid changes
            self.debounceWorkItem?.cancel()
            let work = DispatchWorkItem {
                Task { @MainActor in
                    onChange()
                }
            }
            self.debounceWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: work)
        }

        source.setCancelHandler {
            close(fd)
        }

        source.resume()

        if url == todoFileURL {
            todoWatcherSource = source
        } else {
            doneWatcherSource = source
        }
    }

    private func stopWatching() {
        todoWatcherSource?.cancel()
        todoWatcherSource = nil
        doneWatcherSource?.cancel()
        doneWatcherSource = nil
    }
}
