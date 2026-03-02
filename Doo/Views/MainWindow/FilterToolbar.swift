import SwiftUI

enum SortOption: String, CaseIterable, Identifiable {
    case priority = "Priority"
    case dateAddedNewest = "Newest"
    case dateAddedOldest = "Oldest"
    case dueDateSoonest = "Due Soonest"
    case alphabetical = "A-Z"
    case dateCompleted = "Date Completed"

    var id: String { rawValue }
}

struct FilterState {
    var searchText = ""
    var sortOption: SortOption = .priority
    var selectedTags: Set<String> = []
    var minPriority: Int = 1
    var maxPriority: Int = 5
    var overdueOnly = false
}

extension FilterState {
    func apply(to tasks: [DooTask]) -> [DooTask] {
        var result = tasks

        // Search
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { task in
                task.title.lowercased().contains(query)
                || (task.description?.lowercased().contains(query) ?? false)
                || (task.notes?.lowercased().contains(query) ?? false)
                || task.tags.contains { $0.lowercased().contains(query) }
            }
        }

        // Tag filter
        if !selectedTags.isEmpty {
            result = result.filter { task in
                !selectedTags.isDisjoint(with: task.tags)
            }
        }

        // Priority filter
        result = result.filter { $0.priority >= minPriority && $0.priority <= maxPriority }

        // Overdue filter
        if overdueOnly {
            result = result.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return DateFormatting.isOverdue(dueDate)
            }
        }

        // Sort
        result.sort { a, b in
            switch sortOption {
            case .priority:
                return a.priority < b.priority
            case .dateAddedNewest:
                return a.dateAdded > b.dateAdded
            case .dateAddedOldest:
                return a.dateAdded < b.dateAdded
            case .dueDateSoonest:
                let aDate = a.dueDate ?? .distantFuture
                let bDate = b.dueDate ?? .distantFuture
                return aDate < bDate
            case .alphabetical:
                return a.title.localizedCompare(b.title) == .orderedAscending
            case .dateCompleted:
                let aDate = a.dateCompleted ?? .distantPast
                let bDate = b.dateCompleted ?? .distantPast
                return aDate > bDate
            }
        }

        return result
    }
}

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
