import SwiftUI

struct SectionEditorPopover: View {
    @State var section: TaskSection
    let availableTags: [String]
    let canDelete: Bool
    let onUpdate: (TaskSection) -> Void
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: DooStyle.Spacing.md) {
            // Section name
            TextField("Section name", text: $section.name)
                .textFieldStyle(.roundedBorder)
                .onChange(of: section.name) { _, _ in onUpdate(section) }

            Divider()

            // Priority pills
            VStack(alignment: .leading, spacing: DooStyle.Spacing.xs) {
                Text("Priority").font(.caption).foregroundStyle(DooStyle.textSecondary)
                HStack(spacing: 2) {
                    ForEach([0, 1, 2], id: \.self) { p in
                        FilterPill("P\(p)", isActive: section.selectedPriorities.contains(p)) {
                            if section.selectedPriorities.contains(p) {
                                section.selectedPriorities.remove(p)
                            } else {
                                section.selectedPriorities.insert(p)
                            }
                            onUpdate(section)
                        }
                    }
                }
            }

            // Status pills
            VStack(alignment: .leading, spacing: DooStyle.Spacing.xs) {
                Text("Status").font(.caption).foregroundStyle(DooStyle.textSecondary)
                HStack(spacing: 2) {
                    ForEach(PipelineStatus.allCases) { status in
                        FilterPill(status.displayName, isActive: section.selectedStatuses.contains(status)) {
                            if section.selectedStatuses.contains(status) {
                                section.selectedStatuses.remove(status)
                            } else {
                                section.selectedStatuses.insert(status)
                            }
                            onUpdate(section)
                        }
                    }
                }
            }

            // Tags
            if !availableTags.isEmpty {
                VStack(alignment: .leading, spacing: DooStyle.Spacing.xs) {
                    Text("Tags").font(.caption).foregroundStyle(DooStyle.textSecondary)
                    TagsDropdown(
                        availableTags: availableTags,
                        selectedTags: Binding(
                            get: { section.selectedTags },
                            set: { section.selectedTags = $0; onUpdate(section) }
                        )
                    )
                }
            }

            // Overdue toggle
            Toggle("Overdue only", isOn: $section.overdueOnly)
                .onChange(of: section.overdueOnly) { _, _ in onUpdate(section) }

            // Search text
            VStack(alignment: .leading, spacing: DooStyle.Spacing.xs) {
                Text("Search").font(.caption).foregroundStyle(DooStyle.textSecondary)
                TextField("Filter text...", text: $section.searchText)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: section.searchText) { _, _ in onUpdate(section) }
            }

            if canDelete {
                Divider()
                Button("Delete Section", role: .destructive) {
                    onDelete()
                    dismiss()
                }
                .foregroundStyle(DooStyle.colorRed)
            }
        }
        .padding(DooStyle.Spacing.md)
        .frame(width: 280)
    }
}
