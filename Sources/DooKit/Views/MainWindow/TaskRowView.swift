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
                                .padding(.horizontal, DooStyle.Spacing.sm - 2)
                                .padding(.vertical, DooStyle.Spacing.xs)
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
        let color = DooStyle.priorityColor(for: task.priority)
        Text("\(task.priority)")
            .font(.caption2.weight(.bold))
            .frame(width: DooStyle.Size.badge, height: DooStyle.Size.badge)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: DooStyle.Radius.badge))
    }
}
