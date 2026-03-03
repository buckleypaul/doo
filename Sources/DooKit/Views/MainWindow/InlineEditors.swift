import SwiftUI

struct InlineTagEditor: View {
    @State private var tags: [String]
    let taskID: UUID
    let store: TaskStore
    @State private var newTag = ""
    @FocusState private var isFieldFocused: Bool

    init(task: DooTask, store: TaskStore) {
        self._tags = State(initialValue: task.tags)
        self.taskID = task.id
        self.store = store
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DooStyle.Spacing.sm) {
            if !tags.isEmpty {
                FlowLayout(spacing: DooStyle.Spacing.xs) {
                    ForEach(tags, id: \.self) { tag in
                        HStack(spacing: 2) {
                            Text(tag).font(.caption)
                            Button {
                                removeTag(tag)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption2)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, DooStyle.Spacing.sm - 2)
                        .padding(.vertical, DooStyle.Spacing.xs)
                        .background(DooStyle.tagBg)
                        .clipShape(Capsule())
                    }
                }
            }

            TextField("Add tag", text: $newTag)
                .textFieldStyle(.roundedBorder)
                .focused($isFieldFocused)
                .onSubmit { addTag() }
                .frame(width: 160)
        }
        .padding(DooStyle.Spacing.md)
        .onAppear { isFieldFocused = true }
    }

    private func addTag() {
        let tag = newTag.trimmingCharacters(in: .whitespaces).lowercased()
        guard !tag.isEmpty, !tags.contains(tag) else { return }
        tags.append(tag)
        newTag = ""
        save()
    }

    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
        save()
    }

    private func save() {
        guard let index = store.activeTasks.firstIndex(where: { $0.id == taskID }) else { return }
        var updated = store.activeTasks[index]
        updated.tags = tags
        store.updateTask(updated)
    }
}

struct InlineStatusEditor: View {
    let task: DooTask
    let store: TaskStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(PipelineStatus.allCases) { status in
                Button {
                    var updated = task
                    updated.status = status
                    store.updateTask(updated)
                    dismiss()
                } label: {
                    HStack {
                        Text(status.displayName)
                            .font(.callout)
                        Spacer()
                        if task.status == status {
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .foregroundStyle(DooStyle.accent)
                        }
                    }
                    .contentShape(Rectangle())
                    .padding(.horizontal, DooStyle.Spacing.md)
                    .padding(.vertical, DooStyle.Spacing.sm)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(minWidth: 160)
    }
}

struct InlineDueDateEditor: View {
    @State private var date: Date
    @State private var hasDueDate: Bool
    let taskID: UUID
    let store: TaskStore
    @Environment(\.dismiss) private var dismiss

    init(task: DooTask, store: TaskStore) {
        self._date = State(initialValue: task.dueDate ?? Date())
        self._hasDueDate = State(initialValue: task.dueDate != nil)
        self.taskID = task.id
        self.store = store
    }

    var body: some View {
        VStack(spacing: DooStyle.Spacing.sm) {
            DatePicker("", selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .onChange(of: date) { _, newDate in
                    hasDueDate = true
                    save(date: newDate)
                }
            if hasDueDate {
                Button("Clear Date") {
                    hasDueDate = false
                    save(date: nil)
                    dismiss()
                }
                .foregroundStyle(DooStyle.colorRed)
                .font(.callout)
                .padding(.bottom, DooStyle.Spacing.xs)
            }
        }
        .padding(DooStyle.Spacing.md)
    }

    private func save(date: Date?) {
        guard let index = store.activeTasks.firstIndex(where: { $0.id == taskID }) else { return }
        var updated = store.activeTasks[index]
        updated.dueDate = date
        store.updateTask(updated)
    }
}
