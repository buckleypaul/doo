# Settings Migration Design

**Date:** 2026-03-02
**Status:** Approved

## Goal

Migrate `SettingsManager` from `UserDefaults` to a plain JSON file at `~/.config/doo/settings.json`. Move default data file locations from `~/doo-*.json` to `~/.local/share/doo/`.

## File Locations

| Purpose | Path |
|---------|------|
| Settings | `~/.config/doo/settings.json` |
| Todo data | `~/.local/share/doo/todo.json` |
| Done data | `~/.local/share/doo/done.json` |

## JSON Schema

```json
{
  "todoFilePath": "~/.local/share/doo/todo.json",
  "doneFilePath": "~/.local/share/doo/done.json",
  "hotkeyEnabled": true,
  "launchAtLogin": false
}
```

## Architecture

### `SettingsConfig` (new inner struct)

A private `Codable` struct holding the four settings fields. Used solely for JSON encode/decode.

### `SettingsManager` changes

- Remove all `UserDefaults` reads and writes
- `init()` resolves `~/.config/doo/settings.json`, reads and decodes `SettingsConfig`; falls back to defaults if file is missing or corrupt
- Each property `didSet` performs an atomic write: encode to `Data`, write to `.settings.tmp`, then `FileManager.replaceItemAt`
- Directory `~/.config/doo/` is created (with intermediates) on first write if absent
- Directory `~/.local/share/doo/` is created on first launch if absent (before `TaskStore` opens files)

### No migration

No UserDefaults migration — single user, clean slate.

## Testing

New `SettingsManagerTests` suite in `Tests/DooTests/Services/`:

- **Fresh init, no file** — defaults are correct (`~/.local/share/doo/` paths, `hotkeyEnabled: true`, `launchAtLogin: false`)
- **Round-trip** — change a property, re-init from the same file, value persists
- **Corrupt file** — file contains invalid JSON, init falls back to defaults without crashing
- All tests use a temp directory injected via a testable init overload; no real `~/.config` written during tests
