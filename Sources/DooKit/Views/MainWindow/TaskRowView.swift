import SwiftUI

struct TaskRowView: View {
    let task: DooTask
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Button(action: onToggle) {
                Image(systemName: task.dateCompleted != nil ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(task.dateCompleted != nil ? .green : .secondary)
            }
            .buttonStyle(.plain)

            priorityBadge

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.dateCompleted != nil)
                    .foregroundStyle(task.dateCompleted != nil ? .secondary : .primary)

                if let description = task.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if !task.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(task.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.quaternary)
                                .clipShape(Capsule())
                        }
                    }
                }

                if !task.subtasks.isEmpty {
                    let completed = task.subtasks.filter(\.completed).count
                    Text("\(completed)/\(task.subtasks.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if let dueDate = task.dueDate {
                    Text(DateFormatting.dateOnly(dueDate))
                        .font(.caption)
                        .foregroundStyle(DateFormatting.isOverdue(dueDate) && task.dateCompleted == nil ? .red : .secondary)
                }

                if let dateCompleted = task.dateCompleted {
                    Text("Done \(DateFormatting.relative(dateCompleted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(DateFormatting.relative(task.dateAdded))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var priorityBadge: some View {
        Text("\(task.priority)")
            .font(.caption2.weight(.bold))
            .frame(width: 18, height: 18)
            .background(priorityColor.opacity(0.2))
            .foregroundStyle(priorityColor)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var priorityColor: Color {
        switch task.priority {
        case 0: .red
        case 1: .orange
        default: .gray
        }
    }
}
