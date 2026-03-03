import SwiftUI

struct FilterToolbar: View {
    @Binding var filterState: FilterState
    let availableTags: [String]
    let showDateCompleted: Bool

    @State private var showTagsPopover = false
    @State private var tagSearch = ""

    var body: some View {
        HStack(spacing: 8) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search tasks...", text: $filterState.searchText)
                    .textFieldStyle(.plain)
                if !filterState.searchText.isEmpty {
                    Button {
                        filterState.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .frame(maxWidth: 250)

            Spacer()

            // Sort
            Picker("Sort", selection: $filterState.sortOption) {
                ForEach(sortOptions, id: \.id) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 140)

            // Priority pills
            HStack(spacing: 2) {
                ForEach([1, 2, 3, 4, 5], id: \.self) { p in
                    FilterPill("P\(p)", isActive: filterState.selectedPriorities.contains(p)) {
                        if filterState.selectedPriorities.contains(p) {
                            filterState.selectedPriorities.remove(p)
                        } else {
                            filterState.selectedPriorities.insert(p)
                        }
                    }
                }
            }

            // Tags pill
            if !availableTags.isEmpty {
                let label = filterState.selectedTags.isEmpty
                    ? "Tags"
                    : "Tags (\(filterState.selectedTags.count))"
                FilterPill(label, isActive: !filterState.selectedTags.isEmpty) {
                    showTagsPopover.toggle()
                }
                .popover(isPresented: $showTagsPopover) {
                    TagsPopover(
                        availableTags: availableTags,
                        selectedTags: $filterState.selectedTags,
                        search: $tagSearch
                    )
                }
                .onChange(of: showTagsPopover) { _, isPresented in
                    if !isPresented { tagSearch = "" }
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

    private var sortOptions: [SortOption] {
        showDateCompleted ? SortOption.allCases : SortOption.allCases.filter { $0 != .dateCompleted }
    }
}

// MARK: - FilterPill

private struct FilterPill: View {
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
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isActive ? Color.accentColor : Color.primary.opacity(0.1))
                .foregroundStyle(isActive ? Color.white : Color.primary)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - TagsPopover

private struct TagsPopover: View {
    let availableTags: [String]
    @Binding var selectedTags: Set<String>
    @Binding var search: String

    private var filteredTags: [String] {
        search.isEmpty ? availableTags : availableTags.filter {
            $0.localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if availableTags.count > 12 {
                TextField("Search tags...", text: $search)
                    .textFieldStyle(.roundedBorder)
            }
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 6) {
                    ForEach(filteredTags, id: \.self) { tag in
                        FilterPill(tag, isActive: selectedTags.contains(tag)) {
                            if selectedTags.contains(tag) {
                                selectedTags.remove(tag)
                            } else {
                                selectedTags.insert(tag)
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
        .frame(minWidth: 200, maxWidth: 300, maxHeight: 300)
    }
}
