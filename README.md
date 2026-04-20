# cc-skill

A Claude Code plugin that checks SKILL.md files against 14 skill-authoring patterns and rewrites weak ones to be stronger.

## What You Get

Two commands:

- **`/skill:check`** scores a SKILL.md against authoring best practices and tests whether its description triggers correctly
- **`/skill:enhance`** rewrites the skill to fill in missing patterns, preserving your original intent and voice

## Installation

Register the `skill/` directory as a plugin in your Claude Code settings. That's it.

If you also have the [prompt plugin](https://github.com/anthropics/cc-prompt) installed, both commands pick it up at runtime for deeper prompt-pattern analysis. Without it, everything works fine on its own.

## Usage

```bash
# Check a skill file
/skill:check path/to/SKILL.md

# Enhance a weak skill
/skill:enhance path/to/SKILL.md

# Check from conversation context (after reading a SKILL.md)
/skill:check
```

## The 14 Patterns

| Category | Patterns |
|----------|----------|
| Discovery | Activation Metadata, Exclusion Clause |
| Context Economy | Context Budget, Progressive Disclosure |
| Instruction Calibration | Control Tuning, Explain-the-Why, Template Scaffold, In-Skill Examples, Known Gotchas |
| Workflow Control | Execution Checklist, Self-Correcting Loop, Plan-Validate-Execute |
| Executable Code | Utility Bundle |
| Meta | Autonomy Calibration |

Each pattern gets one of four statuses:

| Status | Meaning |
|--------|---------|
| **strong** | Pattern meets quality criteria |
| **present** | Detectable but has quality issues |
| **absent** | Not found in the skill |
| **N/A** | Does not apply to this skill type |

## How the Checker Works

The checker reads the SKILL.md and inspects its parent directory (scripts, referenced files, sibling .md files). For each pattern, it applies detection signals and quality criteria from the knowledge file. The output includes an activation test that predicts which user requests would (and wouldn't) trigger the skill.

## How the Enhancer Works

The enhancer runs the same evaluation, then rewrites the skill to address absent and weak patterns. It prioritizes absent patterns first, then strengthens present-but-weak ones. If the skill needs splitting (Progressive Disclosure), it proposes new files for your approval before creating them. If every applicable pattern is already strong, it tells you so and leaves the skill alone.
