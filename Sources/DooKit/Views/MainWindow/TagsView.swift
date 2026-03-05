import SwiftUI

struct TagsView: View {
    @Bindable var store: TaskStore
    @Bindable var settings: SettingsManager

    @State private var selectedTag: String?
    @State private var editingTag: String?
    @State private var editingText = ""
    @State private var showColorPicker = false
    @State private var colorPickerTag: String?
    @State private var showMergePicker = false
    @State private var mergeSourceTag: String?

    private var allTags: [String] {
        Array(Set(store.activeTasks.flatMap(\.tags))).sorted()
    }

    private var filteredTasks: [DooTask] {
        guard let tag = selectedTag else { return [] }
        return store.activeTasks.filter { $0.tags.contains(tag) }
    }

    var body: some View {
        if allTags.isEmpty {
            ContentUnavailableView(
                "No Tags",
                systemImage: "tag",
                description: Text("Tags will appear here as you add them to tasks.")
            )
            .frame(maxHeight: .infinity)
        } else {
            HSplitView {
                // Left column: tag list
                VStack(spacing: 0) {
                    Text("Tags")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(DooStyle.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(DooStyle.Spacing.md)
                        .background(DooStyle.surface)
                    Divider()
                    ScrollView {
                        VStack(alignment: .leading, spacing: DooStyle.Spacing.sm) {
                            ForEach(allTags, id: \.self) { tag in
                                tagRowView(tag: tag)
                            }
                        }
                        .padding(DooStyle.Spacing.md)
                    }
                }
                .frame(minWidth: 200, idealWidth: 220)

                Divider()

                // Right column: task list filtered by selected tag
                if let selected = selectedTag {
                    VStack(spacing: 0) {
                        Text(selected)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(DooStyle.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(DooStyle.Spacing.md)
                            .background(DooStyle.surface)
                        Divider()
                        if filteredTasks.isEmpty {
                            ContentUnavailableView(
                                "No Tasks",
                                systemImage: "checkmark.circle",
                                description: Text("No active tasks with this tag.")
                            )
                            .frame(maxHeight: .infinity)
                        } else {
                            ScrollView {
                                VStack(alignment: .leading, spacing: DooStyle.Spacing.sm) {
                                    ForEach(filteredTasks) { task in
                                        tagTaskRow(task: task)
                                    }
                                }
                                .padding(DooStyle.Spacing.md)
                            }
                        }
                    }
                } else {
                    VStack {
                        Text("Select a tag")
                            .foregroundStyle(DooStyle.textSecondary)
                            .frame(maxHeight: .infinity)
                    }
                }
            }
        }
    }

    private func tagRowView(tag: String) -> some View {
        let tagColor = DooStyle.tagColor(for: tag, settings: settings)
        let bgColor = tagColor ?? DooStyle.tagBg
        let textColor = tagColor.flatMap { _ in
            if let hex = settings.tagColors[tag] {
                return DooStyle.contrastColor(for: hex)
            }
            return nil
        } ?? DooStyle.textPrimary

        let taskCount = store.activeTasks.filter { $0.tags.contains(tag) }.count

        return VStack(alignment: .leading, spacing: DooStyle.Spacing.sm) {
            HStack(spacing: DooStyle.Spacing.sm) {
                // Tag pill with color
                HStack(spacing: DooStyle.Spacing.xs) {
                    Text(tag)
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("\(taskCount)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, DooStyle.Spacing.sm)
                .padding(.vertical, 4)
                .background(bgColor)
                .foregroundStyle(textColor)
                .clipShape(Capsule())

                Spacer()

                // Color swatch button
                Button {
                    colorPickerTag = tag
                    showColorPicker = true
                } label: {
                    Image(systemName: "circle.fill")
                        .font(.caption)
                        .foregroundStyle(bgColor)
                }
                .buttonStyle(.plain)
                .help("Change color")

                // Rename button
                Button {
                    editingTag = tag
                    editingText = tag
                } label: {
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundStyle(DooStyle.textSecondary)
                }
                .buttonStyle(.plain)
                .help("Rename")

                // Merge button
                Button {
                    mergeSourceTag = tag
                    showMergePicker = true
                } label: {
                    Image(systemName: "arrow.merge")
                        .font(.caption)
                        .foregroundStyle(DooStyle.textSecondary)
                }
                .buttonStyle(.plain)
                .help("Merge")
            }
            .contentShape(Rectangle())
            .onTapGesture {
                selectedTag = tag
            }
            .padding(DooStyle.Spacing.sm)
            .background(selectedTag == tag ? DooStyle.accent.opacity(0.1) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: DooStyle.Radius.card))

            // Inline rename field
            if editingTag == tag {
                TextField("Tag name", text: $editingText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { saveRename(from: tag) }
                    .onExitCommand { editingTag = nil }
                    .padding(.horizontal, DooStyle.Spacing.sm)
            }
        }
        .popover(isPresented: Binding(
            get: { colorPickerTag == tag && showColorPicker },
            set: { if !$0 { showColorPicker = false } }
        )) {
            colorPickerPopover(tag: tag)
        }
        .popover(isPresented: Binding(
            get: { mergeSourceTag == tag && showMergePicker },
            set: { if !$0 { showMergePicker = false } }
        )) {
            mergePickerPopover(sourceTag: tag)
        }
    }

    private func tagTaskRow(task: DooTask) -> some View {
        VStack(alignment: .leading, spacing: DooStyle.Spacing.xs) {
            HStack(spacing: DooStyle.Spacing.sm) {
                Button {
                    store.completeTask(task)
                } label: {
                    Image(systemName: "circle")
                        .font(.caption)
                        .foregroundStyle(DooStyle.textSecondary)
                }
                .buttonStyle(.plain)

                Text(task.title)
                    .font(.callout)
                    .lineLimit(1)

                Spacer()

                Text(task.status.displayName)
                    .font(.caption2)
                    .foregroundStyle(DooStyle.textSecondary)
            }
        }
        .contentShape(Rectangle())
        .padding(DooStyle.Spacing.sm)
        .background(DooStyle.tagBg.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: DooStyle.Radius.card))
    }

    private func colorPickerPopover(tag: String) -> some View {
        VStack(alignment: .leading, spacing: DooStyle.Spacing.sm) {
            Text("Tag Color")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(DooStyle.textSecondary)

            // No color option
            Button {
                settings.tagColors.removeValue(forKey: tag)
                showColorPicker = false
            } label: {
                HStack(spacing: DooStyle.Spacing.sm) {
                    Circle()
                        .fill(DooStyle.tagBg)
                        .frame(width: 20, height: 20)
                    Text("No color")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Divider()

            // Color palette
            VStack(alignment: .leading, spacing: DooStyle.Spacing.xs) {
                ForEach(settings.availableTagColors, id: \.name) { color in
                    Button {
                        settings.tagColors[tag] = color.hex
                        showColorPicker = false
                    } label: {
                        HStack(spacing: DooStyle.Spacing.sm) {
                            Circle()
                                .fill(DooStyle.color(fromHex: color.hex) ?? DooStyle.tagBg)
                                .frame(width: 20, height: 20)
                            Text(color.name)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(DooStyle.Spacing.md)
        .frame(width: 200)
    }

    private func mergePickerPopover(sourceTag: String) -> some View {
        VStack(alignment: .leading, spacing: DooStyle.Spacing.sm) {
            Text("Merge into")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(DooStyle.textSecondary)

            Divider()

            VStack(alignment: .leading, spacing: DooStyle.Spacing.xs) {
                ForEach(allTags.filter { $0 != sourceTag }, id: \.self) { targetTag in
                    Button {
                        mergeTags(from: sourceTag, into: targetTag)
                        showMergePicker = false
                    } label: {
                        Text(targetTag)
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(DooStyle.Spacing.md)
        .frame(width: 200)
    }

    private func saveRename(from oldTag: String) {
        let newTag = editingText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !newTag.isEmpty, newTag != oldTag else {
            editingTag = nil
            return
        }

        store.renameTags(from: oldTag, to: newTag)

        // Update tag colors
        if let color = settings.tagColors.removeValue(forKey: oldTag) {
            settings.tagColors[newTag] = color
        }

        editingTag = nil
        selectedTag = newTag
    }

    private func mergeTags(from source: String, into target: String) {
        store.mergeTags(source: source, into: target)

        // Remove source tag color
        settings.tagColors.removeValue(forKey: source)

        selectedTag = target
    }
}
