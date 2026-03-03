# Design: doo:tasks Claude Code Skill

**Date:** 2026-03-03

## Motivation

The `doo` CLI has a rich task management interface. Exposing it as a Claude Code skill lets
other workflows (e.g. meeting notes, code review follow-ups, PR triage) read and create
tasks without the user having to manually craft CLI commands.

Example use case: "Add the action items from this meeting to my doo list" → Claude extracts
tasks, proposes them for confirmation, then executes the adds.

## Approach

A skill file in the user's personal skills marketplace at:

```
~/projects/work-tools/buckleypaul-skills/plugins/doo/skills/tasks/SKILL.md
```

This is preferred over an MCP server (simpler, no daemon) or a shell function (less context-aware).

## Permission Model

- **Read operations** (list, show): no confirmation required
- **Write operations** (add, edit, complete, delete, move): always present proposed changes and
  wait for explicit user confirmation before executing

This is the user's personal task list — the skill must never autonomously create or modify tasks.

## Skill Location

```
plugins/doo/
  .claude-plugin/plugin.json   # plugin manifest
  skills/tasks/SKILL.md        # doo:tasks skill
```

## Key Design Decisions

- Use `--json` output for all reads to enable reliable parsing
- Present proposed tasks using inline syntax so users can review exactly what will be added
- Never use this skill for AI internal tracking — only explicit user requests
- Keep skill in sync with CLI: update when commands, flags, syntax, or schema change

## Maintenance

When any of the following change in the doo codebase, update the skill file:
- CLI commands or flags (`Sources/DooCLILib/Commands/`)
- Inline syntax parser (`Sources/DooCore/Services/InlineSyntaxParser.swift`)
- Pipeline status values (`Sources/DooCore/Models/PipelineStatus.swift`)
- JSON output schema (`Sources/DooCore/Models/DooTask.swift`)
