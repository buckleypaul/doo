# Frontend Design Consistency — 2026-03-03

## Problem

UI colours, spacing, corner radii, and font sizes were hardcoded ad-hoc in each view.
This caused visible inconsistencies:
- Tag pill padding differed between TaskRowView (6h/2v) and TaskDetailView (6h/3v)
- Priority colours used `.gray` which doesn't adapt to dark mode (should use `tertiaryLabelColor`)
- Filter pills used `Color.primary.opacity(0.1)` for inactive background (semantically wrong)
- Hint text still said `!1-5` after priorities were reduced to 0–2
- Quick-add hint was `.tertiary` — nearly invisible on `.ultraThinMaterial`

## Approach

**Approach B — Minimal shared constants + targeted fixes.**

Create a single `DooStyle.swift` enum with:
- `priorityColor(for:)` — maps 0/1/2 to `.red` / `.orange` / `tertiaryLabelColor`
- `Spacing` — xs=4, sm=8, md=12, lg=16
- `Radius` — badge=4, pill=6, card=8, panel=12
- `Size` — badge=18, icon=16

Then fix each affected view to use these constants.

## Files Changed

| File | Change |
|------|--------|
| `Sources/DooKit/DooStyle.swift` | New — shared design constants |
| `Sources/DooKit/Views/MainWindow/TaskRowView.swift` | Use DooStyle colours/sizes, remove strikethrough on completed |
| `Sources/DooKit/Views/MainWindow/TaskDetailView.swift` | Normalise tag pill padding, use DooStyle spacing |
| `Sources/DooKit/Views/MainWindow/FilterToolbar.swift` | Use DooStyle pill radius/padding, fix inactive bg color |
| `Sources/DooKit/Views/MainWindow/TodoListView.swift` | Fix hint text `!1-5` → `!0-2`, use DooStyle spacing |
| `Sources/DooKit/Views/QuickAdd/QuickAddView.swift` | Fix hint text, hint contrast (tertiary→secondary), soften shadow |

## Design Decisions

- **Native macOS aesthetic**: use system colors (`.red`, `.orange`, `tertiaryLabelColor`) — adapts to dark mode automatically.
- **No strikethrough on completed tasks**: gray `.secondary` foreground is sufficient signal; strikethrough + gray was double-indication.
- **Filter pill inactive background**: `Color.secondary.opacity(0.1)` is more semantically correct than `Color.primary.opacity(0.1)`.
- **Quick-add hint contrast**: `.secondary` instead of `.tertiary` — tertiary is nearly invisible against `.ultraThinMaterial`.
- **Shadow**: reduced from `radius:20, y:10` to `radius:16, y:8` — slightly more restrained for a floating panel.
