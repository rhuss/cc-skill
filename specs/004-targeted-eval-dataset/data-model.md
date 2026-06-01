# Data Model: Targeted Eval Dataset

## Entities

### Enhancement Diff Entry

Extracted from the "What Changed" table in `/skill:enhance` output.

| Field | Type | Source |
|-------|------|--------|
| pattern_name | string | "Pattern Applied" column |
| change_description | string | "What was added/changed" column |
| reason | string | "Why" column |

Parsed as a list of entries. One entry per table row (one per enhanced pattern).

### Enhancement Status Entry

Extracted from the "Status Change" table in `/skill:enhance` output.

| Field | Type | Source |
|-------|------|--------|
| pattern_name | string | "Pattern" column |
| before_status | string (absent/present/strong/N/A) | "Before" column |
| after_status | string (absent/present/strong/N/A) | "After" column |

Used to confirm which patterns genuinely improved (before != after).

### Targeted Test Case (on disk)

Directory structure under `eval/cases/`:

```
case-NNN-targeted-<pattern-slug>/
├── input.yaml
├── target-skill/
│   └── SKILL.md
└── annotations.yaml
```

**input.yaml**:
| Field | Type | Description |
|-------|------|-------------|
| skill_path | string | Always `target-skill/SKILL.md` |

**annotations.yaml**:
| Field | Type | Description |
|-------|------|-------------|
| description | string | Human-readable description of what this case tests |
| targets_pattern | string | Pattern name this case exercises (new field for traceability) |
| expected_strong | list[string] | Patterns expected to rate "strong" |
| expected_absent | list[string] | Patterns expected to rate "absent" |
| expected_na | list[string] | Patterns expected to rate "N/A" |
| min_patterns_present | integer | Minimum patterns rated present or strong |

**target-skill/SKILL.md**: A synthetic SKILL.md designed to exercise the targeted pattern. For example, a case targeting "Known Gotchas" would include a skill operating in a domain with obvious pitfalls but no gotcha documentation.

### eval.yaml Configuration (extended)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| targeted_cases_per_pattern | integer | 1 | Max cases to generate per enhanced pattern (1-2) |

Location: under `dataset` section in `eval.yaml`.

## Relationships

```
Enhancement Diff Entry 1:1 Enhancement Status Entry (joined on pattern_name)
Enhancement Diff Entry 1:N Targeted Test Case (1-2 cases per pattern)
Targeted Test Case ∈ eval/cases/ (merged alongside existing cases)
```

## State Transitions

### Targeted Case Lifecycle

```
[not exists] → Generated → Reviewed → Approved → Merged into eval/cases/
                              ↓
                           Rejected → Removed from disk
```

- **Generated**: Case directory written to `eval/cases/` by the generation step
- **Reviewed**: Presented in the interactive review prompt
- **Approved**: User confirms "y" or "edit" then confirms
- **Rejected**: User selects "n"; case directory is deleted
- **Merged**: Cases remain in `eval/cases/` for both baseline and enhanced eval runs
