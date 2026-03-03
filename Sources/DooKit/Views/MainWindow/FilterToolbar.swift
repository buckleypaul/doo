import SwiftUI

struct FilterToolbar: View {
    @Binding var filterState: FilterState
    let availableTags: [String]
    let showDateCompleted: Bool

    var body: some View {
        HStack {
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

            // Filter popover
            Menu {
                // Priority range
                Menu("Priority") {
                    ForEach(1...5, id: \.self) { p in
                        Toggle("P\(p)", isOn: Binding(
                            get: { p >= filterState.minPriority && p <= filterState.maxPriority },
                            set: { enabled in
                                if enabled {
                                    filterState.minPriority = min(filterState.minPriority, p)
                                    filterState.maxPriority = max(filterState.maxPriority, p)
                                } else {
                                    if p == filterState.minPriority { filterState.minPriority = p + 1 }
                                    if p == filterState.maxPriority { filterState.maxPriority = p - 1 }
                                }
                            }
                        ))
                    }
                }

                // Tags
                if !availableTags.isEmpty {
                    Menu("Tags") {
                        ForEach(availableTags, id: \.self) { tag in
                            Toggle(tag, isOn: Binding(
                                get: { filterState.selectedTags.contains(tag) },
                                set: { selected in
                                    if selected {
                                        filterState.selectedTags.insert(tag)
                                    } else {
                                        filterState.selectedTags.remove(tag)
                                    }
                                }
                            ))
                        }
                    }
                }

                Divider()

                Toggle("Overdue Only", isOn: $filterState.overdueOnly)

                Divider()

                Button("Reset Filters") {
                    filterState = FilterState()
                }
            } label: {
                Label("Filter", systemImage: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }

    private var sortOptions: [SortOption] {
        if showDateCompleted {
            return SortOption.allCases
        } else {
            return SortOption.allCases.filter { $0 != .dateCompleted }
        }
    }

    private var hasActiveFilters: Bool {
        !filterState.selectedTags.isEmpty
        || filterState.minPriority != 1
        || filterState.maxPriority != 5
        || filterState.overdueOnly
    }
}
