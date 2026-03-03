---
name: sync-doo-skill
enabled: true
event: file
conditions:
  - field: file_path
    operator: regex_match
    pattern: Sources/DooCLILib/Commands/.*\.swift$|Sources/DooCore/Services/InlineSyntaxParser\.swift$|Sources/DooCore/Models/PipelineStatus\.swift$|Sources/DooCore/Models/DooTask\.swift$
---

If this change affects CLI commands, flags, or output format, update the doo:tasks skill at `~/projects/work-tools/buckleypaul-skills/plugins/doo/skills/tasks/SKILL.md`.

Changes that require a skill update:
- New or renamed subcommands/flags in `DooCLILib/Commands/`
- New inline syntax tokens in `InlineSyntaxParser.swift`
- New or renamed pipeline statuses in `PipelineStatus.swift`
- New fields or changed field names in the `--json` output (`DooTask.swift`)
