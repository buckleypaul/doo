import SwiftUI

struct TaskDetailView: View {
    @Bindable var store: TaskStore
    @Binding var task: DooTask
    @State private var newSubtaskTitle = ""
    @State private var newTag = ""

    var body: some View {
        Form {
            Section("Details") {
                TextField("Title", text: $task.title)

                TextField("Description", text: Binding(
                    get: { task.description ?? "" },
                    set: { task.description = $0.isEmpty ? nil : $0 }
                ))

                TextEditor(text: Binding(
                    get: { task.notes ?? "" },
                    set: { task.notes = $0.isEmpty ? nil : $0 }
                ))
                .frame(minHeight: 60)
                .font(.body)
            }

            Section("Priority") {
                Picker("Priority", selection: $task.priority) {
                    Text("1 — Highest").tag(1)
                    Text("2 — High").tag(2)
                    Text("3 — Medium").tag(3)
                    Text("4 — Low").tag(4)
                    Text("5 — Lowest").tag(5)
                }
                .pickerStyle(.segmented)
            }

            Section("Due Date") {
                Toggle("Has due date", isOn: Binding(
                    get: { task.dueDate != nil },
                    set: { enabled in
                        if enabled {
                            task.dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
                        } else {
                            task.dueDate = nil
                        }
                    }
                ))
                if let dueDate = task.dueDate {
                    DatePicker("Due", selection: Binding(
                        get: { dueDate },
                        set: { task.dueDate = $0 }
                    ), displayedComponents: .date)
                }
            }

            Section("Tags") {
                FlowLayout(spacing: 4) {
                    ForEach(task.tags, id: \.self) { tag in
                        HStack(spacing: 2) {
                            Text(tag)
                                .font(.caption)
                            Button {
                                task.tags.removeAll { $0 == tag }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption2)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.quaternary)
                        .clipShape(Capsule())
                    }
                }

                HStack {
                    TextField("Add tag", text: $newTag)
                        .onSubmit { addTag() }
                    Button("Add", action: addTag)
                        .disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            Section("Subtasks") {
                ForEach($task.subtasks) { $subtask in
                    HStack {
                        Button {
                            subtask.completed.toggle()
                        } label: {
                            Image(systemName: subtask.completed ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(subtask.completed ? .green : .secondary)
                        }
                        .buttonStyle(.plain)

                        TextField("Subtask", text: $subtask.title)
                            .strikethrough(subtask.completed)

                        Spacer()

                        Button {
                            task.subtasks.removeAll { $0.id == subtask.id }
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack {
                    TextField("Add subtask", text: $newSubtaskTitle)
                        .onSubmit { addSubtask() }
                    Button("Add", action: addSubtask)
                        .disabled(newSubtaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .formStyle(.grouped)
        .onChange(of: task) { _, newValue in
            store.updateTask(newValue)
        }
    }

    private func addTag() {
        let tag = newTag.trimmingCharacters(in: .whitespaces).lowercased()
        guard !tag.isEmpty, !task.tags.contains(tag) else { return }
        task.tags.append(tag)
        newTag = ""
    }

    private func addSubtask() {
        let title = newSubtaskTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        task.subtasks.append(Subtask(title: title))
        newSubtaskTitle = ""
    }
}

// Simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(in: proposal.width ?? 0, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(in: bounds.width, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(subviews[index].sizeThatFits(.unspecified))
            )
        }
    }

    private func layout(in width: CGFloat, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: width, height: y + rowHeight), positions)
    }
}
