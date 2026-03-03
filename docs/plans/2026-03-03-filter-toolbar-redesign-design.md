# Filter Toolbar Redesign

**Date:** 2026-03-03

## Goal

Replace the single "Filter" dropdown menu with individual inline controls in the toolbar — one per filter type — so filter state is visible and accessible without opening a menu.

## Layout

```
[🔍 Search tasks...  ×]          [Sort ▾]  [P1][P2][P3][P4][P5]  [Tags ▾]  [Overdue]
```

- Search stays left, max 250px
- Sort picker unchanged
- P1–P5: a horizontal group of toggleable pills (~28px wide each)
- Tags pill: opens a popover; hidden when no tags exist
- Overdue: a single toggleable pill

## FilterState Model Change

Replace `minPriority: Int` and `maxPriority: Int` with:

```swift
public var selectedPriorities: Set<Int> = []
```

Empty = no priority filter (all tasks shown). Filter logic:

```swift
selectedPriorities.isEmpty || selectedPriorities.contains($0.priority)
```

`hasActiveFilters` uses `!selectedPriorities.isEmpty` instead of the range check.

## Priority Pills

- P1–P5 rendered as a horizontal group with no inter-pill spacing (segmented feel)
- Each pill independently toggles its value in `selectedPriorities`
- Active: `.tint` / accent fill; inactive: `.quaternary` background
- No pills dimmed based on current task data — always fully interactive

## Tags Popover

- Anchored to the Tags pill button
- Label: "Tags" (none selected) or "Tags (N)" (N selected)
- Contents:
  - Search field ("Search tags...") shown only when tag count > 12
  - Scrollable chip grid of tags filtered by search text
  - Each chip toggles membership in `filterState.selectedTags`
  - No confirm button — changes apply immediately
- Pill hidden when `availableTags` is empty

## Overdue Pill

- Single toggleable pill bound to `filterState.overdueOnly`
- Active state uses accent fill, same as priority pills

## Visual Style

All pills share a common style:
- Inactive: `.quaternary` background, default label colour
- Active: `.tint` background fill, white/primary label
- Corner radius consistent with existing search field (8pt)
- Font: `.callout` or `.footnote` to keep pills compact

## Files Changed

- `Sources/DooCore/Services/FilterState.swift` — model change
- `Sources/DooKit/Views/MainWindow/FilterToolbar.swift` — full rewrite of filter section
- `Tests/DooTests/Services/FilterStateTests.swift` — update priority filter tests
