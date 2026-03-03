# Syntax Hint Row Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a persistent, always-visible syntax hint row below the inline task input field showing the four inline syntax tokens (`!1-5`, `#tag`, `@today`, `/text`).

**Architecture:** Modify `InlineAddRow` in `TodoListView.swift` — wrap the existing `HStack` (TextField + button) and a new `SyntaxHintRow` in a `VStack(spacing: 4)`. Move the outer padding to the `VStack`. No logic changes, no new state.

**Tech Stack:** SwiftUI (macOS 15+), Swift 6.

---

### Task 1: Add persistent syntax hint row to InlineAddRow

**Files:**
- Modify: `Sources/DooKit/Views/MainWindow/TodoListView.swift`

**Step 1: Read the current file**

Read `Sources/DooKit/Views/MainWindow/TodoListView.swift` to confirm current state. The relevant section is the `private struct InlineAddRow` at the bottom (currently lines 100–127).

**Step 2: Replace `InlineAddRow` with the updated version**

Find and replace the entire `private struct InlineAddRow` block with:

```swift
private struct InlineAddRow: View {
    @Binding var input: String
    var isFocused: FocusState<Bool>.Binding
    let onSubmit: () -> Void

    private var isInputEmpty: Bool {
        input.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                TextField("Add a task...", text: $input)
                    .textFieldStyle(.plain)
                    .focused(isFocused)
                    .onSubmit { onSubmit() }

                Button(action: onSubmit) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(isInputEmpty ? Color.secondary : Color.accentColor)
                }
                .buttonStyle(.plain)
                .disabled(isInputEmpty)
            }

            HStack(spacing: 16) {
                hintItem("!1-5", label: "priority")
                hintItem("#tag", label: "tag")
                hintItem("@today", label: "or @tomorrow")
                hintItem("/text", label: "description")
            }
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func hintItem(_ code: String, label: String) -> some View {
        HStack(spacing: 2) {
            Text(code)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            Text(label)
        }
    }
}
```

Key changes from the previous version:
- `body` is now a `VStack(alignment: .leading, spacing: 4)` wrapping the input `HStack` and the hint `HStack`
- The placeholder text is simplified back to `"Add a task..."` (the hint row replaces the placeholder hint)
- A `hintItem(_:label:)` helper renders each token/label pair
- Outer `.padding` stays on the `VStack`

**Step 3: Build**

```bash
swift build 2>&1 | head -40
```

Expected: `Build complete!` with no errors. If there are compile errors, fix them before proceeding.

**Step 4: Commit**

```bash
git add Sources/DooKit/Views/MainWindow/TodoListView.swift
git commit -m "$(cat <<'EOF'
feat: add persistent syntax hint row below inline add field

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: Run full test suite

**Step 1: Run tests**

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test 2>&1 | tail -20
```

Expected: `Test Suite 'All tests' passed` with 128 tests, 0 failures. No new tests needed — this is a purely additive UI change with no logic.
