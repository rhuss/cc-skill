# Skill Plugin Conventions

## Skill Naming

All skills in this plugin use the `skill:` prefix:
- `skill:check` - Evaluate a SKILL.md against authoring patterns
- `skill:enhance` - Improve a SKILL.md by applying missing patterns
- `skill:measure` - Run baseline-enhance-reeval loop with comparison report

## Knowledge Loading

Skills load pattern definitions from `${CLAUDE_PLUGIN_ROOT}/knowledge/skill-authoring-patterns.md`. This file contains the 14 skill-authoring patterns with detection signals, quality criteria, and improvement guidance.

If the knowledge file is unavailable, skills should report the error clearly and halt.

## Optional Prompt Plugin Integration

When the `prompt` plugin is loaded in the current session, skills may delegate prompt-pattern analysis to it (e.g., `/prompt:check`). When unavailable, skills work standalone using skill-authoring patterns only, with no errors or references to the missing plugin.

## File Creation Conventions

When the enhancer creates reference files (Progressive Disclosure):
- Place new files in the same directory as the SKILL.md being enhanced
- Use descriptive lowercase-hyphenated names (e.g., `reference.md`, `examples.md`, `gotchas.md`)
- Present proposed file structure for user approval before creating
