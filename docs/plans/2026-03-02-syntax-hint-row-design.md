# Syntax Hint Row Design

Date: 2026-03-02

## Problem

The inline syntax hints (`!priority #tag @date /desc`) are only visible in the `TextField` placeholder, which disappears as soon as the user starts typing.

## Goal

A persistent, always-visible hint row below the input field showing the four inline syntax tokens.

## Design

### Layout

`InlineAddRow.body` becomes a `VStack(spacing: 4)`:
1. Existing `HStack` (TextField + button)
2. New `SyntaxHintRow` — four hint chips in an `HStack(spacing: 16)`

The outer `.padding(.horizontal, 16).padding(.vertical, 8)` wraps the whole `VStack`.

### SyntaxHintRow contents

| Code   | Label           |
|--------|-----------------|
| `!1-5` | `priority`      |
| `#tag` | `tag`           |
| `@today` | `or @tomorrow` |
| `/text` | `description`  |

### Styling

`.font(.caption)`, `.foregroundStyle(.tertiary)`, matching the existing `QuickAddView` hint pattern.

### Changes

- Modify: `Sources/DooKit/Views/MainWindow/TodoListView.swift` only
- No logic changes, no new state, no new tests needed
