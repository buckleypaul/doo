# Filter Toolbar Redesign Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the single "Filter" dropdown with inline P1–P5 priority pills, a Tags popover pill, and an Overdue toggle pill in the filter toolbar.

**Architecture:** `FilterState` drops the `minPriority`/`maxPriority` range in favour of a `selectedPriorities: Set<Int>`. `FilterToolbar` is rewritten to render priority as 5 toggleable pills, tags as a popover-backed pill, and overdue as a toggle pill. A private `FilterPill` view provides the shared active/inactive pill style.

**Tech Stack:** Swift 6, SwiftUI, XCTest

---

### Task 1: Update FilterState model

**Files:**
- Modify: `Sources/DooCore/Services/FilterState.swift`
- Modify: `Tests/DooTests/Services/FilterStateTests.swift`

**Step 1: Write the failing tests**

In `FilterStateTests.swift`, replace `testFilterByPriorityRange` and `testCombinedSearchAndPriorityFilter` with these three tests:

```swift
func testFilterBySelectedPriorities() {
    let filter = FilterState(selectedPriorities: [1, 2])
    let result = filter.apply(to: tasks)
    XCTAssertEqual(result.count, 2)
    XCTAssertTrue(result.allSatisfy { [1, 2].contains($0.priority) })
}

func testEmptySelectedPrioritiesReturnsAll() {
    let filter = FilterState(selectedPriorities: [])
    let result = filter.apply(to: tasks)
    XCTAssertEqual(result.count, tasks.count)
}

func testNonContiguousPrioritySelection() {
    // tasks fixture: p1 "Fix login bug", p2 "Write docs", p3 "Buy milk", p4 "Deploy app"
    let filter = FilterState(selectedPriorities: [1, 3])
    let result = filter.apply(to: tasks)
    XCTAssertEqual(result.count, 2)
    XCTAssertTrue(result.allSatisfy { [1, 3].contains($0.priority) })
}

func testCombinedSearchAndPriorityFilter() {
    let filter = FilterState(searchText: "bug", selectedPriorities: [1, 2])
    let result = filter.apply(to: tasks)
    XCTAssertEqual(result.count, 1)
    XCTAssertEqual(result[0].title, "Fix login bug")
}
```

**Step 2: Run tests to confirm they fail**

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --filter FilterStateTests 2>&1 | tail -15
```

Expected: compile errors referencing `selectedPriorities` (not yet defined) and missing `minPriority`/`maxPriority` init params.

**Step 3: Update FilterState**

In `Sources/DooCore/Services/FilterState.swift`:

Replace the two priority properties:
```swift
// Remove:
public var minPriority: Int = 1
public var maxPriority: Int = 5

// Add:
public var selectedPriorities: Set<Int> = []
```

Update the `init`:
```swift
public init(
    searchText: String = "",
    sortOption: SortOption = .priority,
    selectedTags: Set<String> = [],
    selectedPriorities: Set<Int> = [],
    overdueOnly: Bool = false
) {
    self.searchText = searchText
    self.sortOption = sortOption
    self.selectedTags = selectedTags
    self.selectedPriorities = selectedPriorities
    self.overdueOnly = overdueOnly
}
```

Replace the priority filter block in `apply(to:)`:
```swift
// Remove:
result = result.filter { $0.priority >= minPriority && $0.priority <= maxPriority }

// Add:
if !selectedPriorities.isEmpty {
    result = result.filter { selectedPriorities.contains($0.priority) }
}
```

**Step 4: Run tests to confirm they pass**

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --filter FilterStateTests 2>&1 | tail -10
```

Expected: all FilterStateTests pass.

**Step 5: Run full test suite**

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test 2>&1 | tail -10
```

Expected: all tests pass. Fix any compile errors if other files reference `minPriority`/`maxPriority`.

**Step 6: Commit**

```bash
git add Sources/DooCore/Services/FilterState.swift Tests/DooTests/Services/FilterStateTests.swift
git commit -m "refactor: replace priority range with selectedPriorities set in FilterState"
```

---

### Task 2: Rewrite FilterToolbar

**Files:**
- Modify: `Sources/DooKit/Views/MainWindow/FilterToolbar.swift`

No unit tests for pure SwiftUI views — verify visually with `swift run Doo`.

**Step 1: Replace FilterToolbar.swift entirely**

```swift
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
                ForEach(1...5, id: \.self) { p in
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
```

**Step 2: Build to verify no compile errors**

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift build 2>&1 | tail -10
```

Expected: `Build complete!`

**Step 3: Run the app and verify visually**

```bash
swift run Doo
```

Check:
- P1–P5 pills appear to the right of the Sort picker
- Clicking a priority pill highlights it (accent fill) and filters the list
- Clicking it again deactivates it
- Tags pill appears only when tasks have tags; shows chip grid in popover; shows "Tags (N)" when N selected
- Overdue pill toggles overdue-only filter
- Search still works as before

**Step 4: Run full test suite**

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test 2>&1 | tail -10
```

Expected: all tests pass.

**Step 5: Commit**

```bash
git add Sources/DooKit/Views/MainWindow/FilterToolbar.swift
git commit -m "feat: replace filter dropdown with inline priority pills, tags popover, and overdue pill"
```
