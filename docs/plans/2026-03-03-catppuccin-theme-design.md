# Catppuccin Theme — Design Document

**Date:** 2026-03-03

## Summary

Replace the app's system-semantic color scheme with the Catppuccin palette to give Doo a more personal, distinctive look.

## Decisions

### Palette flavors

| Mode | Flavor |
|------|--------|
| Light | Latte |
| Dark | Macchiato |

Accent color is **Mauve** (`#8839ef` / `#c6a0f6`).

### Surface strategy

Solid surface colors replace `NSVisualEffectView` sidebar material everywhere **except** the QuickAdd floating panel, which keeps `ultraThinMaterial` for a frosted-glass effect that suits its floating nature.

### Color mapping

| Semantic role | Light (Latte) | Dark (Macchiato) |
|---------------|---------------|------------------|
| `background` | `base` `#eff1f5` | `base` `#24273a` |
| `surface` | `mantle` `#e6e9ef` | `mantle` `#1e2030` |
| `separator` | `crust` `#dce0e8` | `crust` `#181926` |
| `tagBg` | `surface0` `#ccd0da` | `surface0` `#363a4f` |
| `textPrimary` | `text` `#4c4f69` | `text` `#cad3f5` |
| `textSecondary` | `subtext1` `#5c5f77` | `subtext1` `#b8c0e0` |
| `textTertiary` | `subtext0` `#6c6f85` | `subtext0` `#a5adcb` |
| `textOverlay` | `overlay1` `#8c8fa1` | `overlay1` `#8087a2` |
| `accent` | `mauve` `#8839ef` | `mauve` `#c6a0f6` |
| `colorGreen` | `green` `#40a02b` | `green` `#a6da95` |
| `colorRed` | `red` `#d20f39` | `red` `#ed8796` |
| `colorPeach` | `peach` `#fe640b` | `peach` `#f5a97f` |

### Priority colors

| Priority | Color |
|----------|-------|
| P0 | `colorRed` |
| P1 | `colorPeach` |
| P2 | `textOverlay` |

### Architecture

Two new files in `Sources/DooKit/`:
- `Color+Hex.swift` — `Color(hex:)` initializer for 6-digit hex strings
- `CatppuccinPalette.swift` — `CatppuccinPalette.Latte` + `CatppuccinPalette.Macchiato` enums (26 colors each)

`DooStyle.swift` gains:
- `Color(light:dark:)` private extension using `NSColor` appearance switching
- Semantic color constants (`DooStyle.background`, `.surface`, `.accent`, etc.)
- `SidebarMaterial` struct removed; replaced with plain `DooStyle.surface` Color

All views updated to use `DooStyle.*` semantics rather than SwiftUI system colors.
