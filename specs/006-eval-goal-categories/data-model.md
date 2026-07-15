# Data Model: Eval Goal Categories

## Entities

### Judge

A named evaluation check in eval.yaml.

| Field | Description |
|-------|-------------|
| name | Goal-prefixed identifier (e.g., `outcome_checklist_completeness`) |
| category | Extracted from name prefix: outcome, process, style, efficiency |
| type | `builtin`, `check` (deterministic), or `prompt` (model-assisted) |
| threshold_key | Must match the judge name exactly |
| threshold_type | `min_pass_rate` (for deterministic) or `min_mean` (for model-assisted) |

### Goal Category

One of four fixed quality dimensions.

| Category | Purpose | Typical Judge Types |
|----------|---------|-------------------|
| outcome | Did the skill complete its task correctly? | Deterministic checks on output structure, model-assisted accuracy checks |
| process | Did the skill follow its documented procedure? | Deterministic checks on procedure evidence (sections, steps) |
| style | Does the output follow conventions? | Model-assisted quality checks, deterministic format checks |
| efficiency | Did it complete without waste? | Builtin cost budget, model-assisted thrashing detection |

### Invocation Type

Classification of how an eval case invokes the skill.

| Type | Description | Example Prompt |
|------|-------------|----------------|
| explicit | Direct skill invocation with clear input | "Run skill:check on this SKILL.md" |
| implicit | Natural language that should trigger the skill | "How good is this skill?" |
| contextual | Skill-relevant request in broader context | "I need to review a skill before sharing" |

## Relationships

- Each **Judge** belongs to exactly one **Goal Category** (derived from its name prefix).
- Each **eval case** has exactly one **Invocation Type** (from annotations.yaml, defaults to `explicit`).
- Each **eval.yaml** config contains multiple **Judges** spanning all four **Goal Categories**.
- **compare-runs.sh** reads **Judges** from summary.yaml, groups by **Goal Category**, and optionally groups by **Invocation Type**.

## Judge Inventory

### skill-check (7 judges)

| Judge Name | Category | Type | New? |
|-----------|----------|------|------|
| outcome_checklist_completeness | outcome | check | renamed |
| outcome_status_validity | outcome | check | renamed |
| outcome_pattern_accuracy | outcome | prompt | renamed |
| process_evaluation_sequence | process | check | new |
| style_note_specificity | style | prompt | renamed |
| style_summary_format | style | check | new |
| efficiency_budget | efficiency | builtin | renamed |

### skill-enhance (8 judges)

| Judge Name | Category | Type | New? |
|-----------|----------|------|------|
| outcome_output_completeness | outcome | check | renamed |
| outcome_pattern_evaluation | outcome | check | renamed |
| outcome_frontmatter_preserved | outcome | check | renamed |
| outcome_intent_preservation | outcome | prompt | renamed |
| process_step_execution | process | check | new |
| style_changelog_specificity | style | prompt | renamed |
| style_proportionality | style | prompt | renamed |
| efficiency_budget | efficiency | builtin | renamed |
