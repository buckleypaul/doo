import SwiftUI

struct FilterToolbar: View {
    @Binding var filterState: FilterState
    let availableTags: [String]

    @State private var showTagsPopover = false

    var body: some View {
        HStack(spacing: 8) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(DooStyle.textSecondary)
                TextField("Search tasks...", text: $filterState.searchText)
                    .textFieldStyle(.plain)
                if !filterState.searchText.isEmpty {
                    Button {
                        filterState.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(DooStyle.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .background(DooStyle.tagBg)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .frame(maxWidth: 250)

            Spacer()

            // Priority pills
            HStack(spacing: 2) {
                ForEach([0, 1, 2], id: \.self) { p in
                    FilterPill("P\(p)", isActive: filterState.selectedPriorities.contains(p)) {
                        if filterState.selectedPriorities.contains(p) {
                            filterState.selectedPriorities.remove(p)
                        } else {
                            filterState.selectedPriorities.insert(p)
                        }
                    }
                }
            }

            // Status pills
            HStack(spacing: 2) {
                ForEach(PipelineStatus.allCases) { status in
                    FilterPill(status.displayName, isActive: filterState.selectedStatuses.contains(status)) {
                        if filterState.selectedStatuses.contains(status) {
                            filterState.selectedStatuses.remove(status)
                        } else {
                            filterState.selectedStatuses.insert(status)
                        }
                    }
                }
            }

            // Tags dropdown
            if !availableTags.isEmpty {
                let isActive = !filterState.selectedTags.isEmpty
                let label = isActive ? "Tags (\(filterState.selectedTags.count))" : "Tags"
                FilterPill(label, isActive: isActive) {
                    showTagsPopover.toggle()
                }
                .popover(isPresented: $showTagsPopover, arrowEdge: .bottom) {
                    TagsDropdown(
                        availableTags: availableTags,
                        selectedTags: $filterState.selectedTags
                    )
                }
            }

            // Overdue pill
            FilterPill("Overdue", isActive: filterState.overdueOnly) {
                filterState.overdueOnly.toggle()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }

}

// MARK: - FilterPill

struct FilterPill: View {
    let label: String
    let isActive: Bool
    let action: () -> Void

    init(_ label: String, isActive: Bool, action: @escaping () -> Void) {
        self.label = label
        self.isActive = isActive
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.callout)
                .padding(.horizontal, DooStyle.Spacing.sm)
                .padding(.vertical, DooStyle.Spacing.xs)
                .background(isActive ? DooStyle.accent : DooStyle.tagBg.opacity(0.6))
                .foregroundStyle(isActive ? DooStyle.background : DooStyle.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: DooStyle.Radius.pill))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - TagsDropdown

struct TagsDropdown: View {
    let availableTags: [String]
    @Binding var selectedTags: Set<String>

    @State private var hoveredTag: String? = nil
    @State private var hoveringSelectAll = false

    private var allSelected: Bool {
        !availableTags.isEmpty && availableTags.allSatisfy { selectedTags.contains($0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(availableTags, id: \.self) { tag in
                tagRow(tag)
            }
            Divider()
                .padding(.vertical, 2)
            selectAllRow
        }
        .padding(.vertical, 4)
        .frame(minWidth: 160)
    }

    private func tagRow(_ tag: String) -> some View {
        let isSelected = selectedTags.contains(tag)
        return Button {
            if isSelected { selectedTags.remove(tag) } else { selectedTags.insert(tag) }
        } label: {
            HStack(spacing: DooStyle.Spacing.sm) {
                Image(systemName: "checkmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DooStyle.accent)
                    .opacity(isSelected ? 1 : 0)
                    .frame(width: 12)
                Text(tag)
                    .foregroundStyle(DooStyle.textPrimary)
                Spacer()
            }
            .padding(.horizontal, DooStyle.Spacing.md)
            .padding(.vertical, DooStyle.Spacing.xs + 1)
            .background(hoveredTag == tag ? DooStyle.tagBg : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hoveredTag = $0 ? tag : nil }
    }

    private var selectAllRow: some View {
        Button {
            if allSelected { selectedTags.removeAll() }
            else { selectedTags = Set(availableTags) }
        } label: {
            HStack(spacing: DooStyle.Spacing.sm) {
                Color.clear.frame(width: 12)
                Text(allSelected ? "Deselect All" : "Select All")
                    .foregroundStyle(DooStyle.textSecondary)
                Spacer()
            }
            .padding(.horizontal, DooStyle.Spacing.md)
            .padding(.vertical, DooStyle.Spacing.xs + 1)
            .background(hoveringSelectAll ? DooStyle.tagBg : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hoveringSelectAll = $0 }
    }
}
