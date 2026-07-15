# cc-skill Development Guidelines

## Project Structure

```text
cc-skill/
├── CLAUDE.md                         # This file
├── README.md                         # Project overview
└── skill/                            # Plugin root (register this in Claude Code)
    ├── .claude-plugin/
    │   └── plugin.json               # Plugin manifest
    ├── CLAUDE.md                     # Plugin conventions
    ├── skills/
    │   ├── checker/
    │   │   └── SKILL.md              # skill:check command
    │   └── enhancer/
    │       └── SKILL.md              # skill:enhance command
    └── knowledge/
        └── skill-authoring-patterns.md  # 14 patterns
```

## Installation

Register the plugin root (`skill/` directory) in Claude Code settings.

## Testing

Validate skills by running them against real SKILL.md files:
- `/skill:check path/to/SKILL.md` for evaluation
- `/skill:enhance path/to/SKILL.md` for improvement

<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan
at `specs/005-three-layer-linting/plan.md`
<!-- SPECKIT END -->
