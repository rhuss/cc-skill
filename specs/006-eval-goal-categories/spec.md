# Feature Specification: Eval Goal Categories

**Feature Branch**: `006-eval-goal-categories`
**Created**: 2026-07-15
**Status**: Draft
**Input**: Brainstorm #06 (eval-framework) revisit decisions

## User Scenarios & Testing

### User Story 1 - Goal-Category Comparison Report (Priority: P1)

A skill author runs `skill:measure` on a skill, which triggers baseline and enhanced eval runs followed by `compare-runs.sh`. The comparison report groups judges by goal category (outcome, process, style, efficiency) so the author can see which dimension improved, not just which individual judge score changed.

**Why this priority**: This is the core value proposition. Without per-category grouping, the author sees flat judge deltas and must mentally map each judge to its purpose.

**Independent Test**: Run `compare-runs.sh` against two summary.yaml files where judges use goal-category prefixed names. Verify the report groups by category and shows per-category summaries.

**Acceptance Scenarios**:

1. **Given** two eval runs with goal-prefixed judges, **When** `compare-runs.sh` is invoked, **Then** the markdown report groups judges under Outcome, Process, Style, and Efficiency headings with per-category direction summaries.
2. **Given** two eval runs where outcome judges improved but style judges regressed, **When** `compare-runs.sh` is invoked, **Then** the per-category summary shows "Outcome: Improved" and "Style: Regressed" separately.
3. **Given** two eval runs with goal-prefixed judges, **When** `compare-runs.sh` is invoked, **Then** a `comparison.json` file is emitted alongside `comparison.md` with structured per-judge and per-category data.

---

### User Story 2 - Reorganized Eval Judges (Priority: P1)

A skill author reviewing `eval/skill-check/eval.yaml` or `eval/skill-enhance/eval.yaml` can immediately see which quality dimension each judge covers because judge names are prefixed with their goal category (`outcome_`, `process_`, `style_`, `efficiency_`).

**Why this priority**: The judge reorganization is the structural foundation. Without it, the comparison report has nothing to group by.

**Independent Test**: Open either eval.yaml and verify every judge name starts with one of the four goal-category prefixes. Verify all four categories have at least one judge.

**Acceptance Scenarios**:

1. **Given** the `eval/skill-check/eval.yaml` file, **When** a developer reads the judges section, **Then** every judge name starts with `outcome_`, `process_`, `style_`, or `efficiency_` and all four categories are represented.
2. **Given** the `eval/skill-enhance/eval.yaml` file, **When** a developer reads the judges section, **Then** every judge name starts with `outcome_`, `process_`, `style_`, or `efficiency_` and all four categories are represented.
3. **Given** a renamed judge (e.g., `outcome_checklist_completeness`), **When** thresholds are defined, **Then** the threshold key matches the new judge name.

---

### User Story 3 - Typed Invocation Annotations (Priority: P2)

An eval case author adding new test cases to the dataset specifies an `invocation_type` field in `annotations.yaml` to declare whether the case tests explicit, implicit, or contextual skill invocation. The comparison report can then break down results by invocation type.

**Why this priority**: Typed invocations add analytical depth but the eval framework delivers value without them. Existing cases work unchanged (they default to explicit).

**Independent Test**: Add `invocation_type: implicit` to an eval case's annotations.yaml. Run the eval. Verify the invocation type appears in the comparison output.

**Acceptance Scenarios**:

1. **Given** an eval case with `invocation_type: explicit` in annotations.yaml, **When** the eval runs, **Then** judges can reference the invocation type via `{{ annotations }}`.
2. **Given** eval cases with mixed invocation types, **When** `compare-runs.sh` runs, **Then** the JSON output includes per-invocation-type breakdowns.
3. **Given** an eval case with no `invocation_type` field, **When** the eval runs, **Then** the case is treated as `explicit` by default.

---

### Edge Cases

- What happens when a judge name has no recognized goal-category prefix? `compare-runs.sh` groups it under an "other" category with a warning.
- What happens when one eval run has goal-prefixed judges and the other has legacy names? The comparison treats them as different judges (no automatic mapping). The user sees both sets.
- What happens when `comparison.json` cannot be written (permissions, disk full)? The script warns to stderr but still produces the terminal table and markdown report (JSON is best-effort).

## Requirements

### Functional Requirements

- **FR-001**: All judges in `eval/skill-check/eval.yaml` MUST be renamed with goal-category prefixes (`outcome_`, `process_`, `style_`, `efficiency_`).
- **FR-002**: All judges in `eval/skill-enhance/eval.yaml` MUST be renamed with goal-category prefixes.
- **FR-003**: Both eval configs MUST have at least one judge in each of the four goal categories.
- **FR-004**: New deterministic judges MUST be added to fill coverage gaps. Specifically:
  - `skill-check` needs a `process_` judge (e.g., verifying the skill follows a structured evaluation sequence) and an `efficiency_` judge (e.g., verifying cost stays within budget, currently `budget_check`).
  - `skill-enhance` needs an `efficiency_` judge (e.g., verifying cost stays within budget, currently `budget_check`).
  - Existing judges that fit a category (e.g., `budget_check` maps to `efficiency_budget`) MUST be renamed, not duplicated.
- **FR-005**: `compare-runs.sh` MUST group judges by goal category in terminal output, markdown report, and JSON output.
- **FR-006**: `compare-runs.sh` MUST produce a per-category summary line (e.g., "Outcome: Improved, Process: Unchanged, Style: Regressed, Efficiency: Unchanged").
- **FR-007**: `compare-runs.sh` MUST emit a `comparison.json` file alongside `comparison.md` in the enhanced run directory.
- **FR-008**: The `annotations.yaml` schema for eval cases MUST support an optional `invocation_type` field with values `explicit`, `implicit`, or `contextual`.
- **FR-009**: Eval cases without an `invocation_type` field MUST be treated as `explicit` by default.
- **FR-010**: `comparison.json` MUST include per-judge scores, per-category aggregates, and overall summary data. Structure:
  ```json
  {
    "baseline_run_id": "string",
    "enhanced_run_id": "string",
    "judges": {
      "<judge_name>": { "baseline": 0.0, "enhanced": 0.0, "delta": 0.0, "direction": "up|down|same" }
    },
    "categories": {
      "<category>": { "judges": ["..."], "direction": "Improved|Regressed|Unchanged", "avg_delta": 0.0 }
    },
    "summary": { "improved": 0, "regressed": 0, "unchanged": 0 }
  }
  ```
- **FR-011**: Threshold keys in eval.yaml MUST match the new goal-prefixed judge names.
- **FR-012**: Judge names that do not match a recognized goal-category prefix MUST be grouped under "other" with a warning in the comparison output.
- **FR-013**: `compare-runs.sh` MUST extract goal-category prefixes by splitting judge names on the first underscore (e.g., `outcome_checklist_completeness` yields category `outcome`).
- **FR-014**: When eval cases include `invocation_type` annotations, `comparison.json` MUST include a `by_invocation_type` section with per-type breakdowns of judge results.

### Key Entities

- **Judge**: A named evaluation check within eval.yaml. Has a goal-category prefix, a type (deterministic check or model-assisted prompt), and a threshold.
- **Goal Category**: One of four fixed quality dimensions: outcome, process, style, efficiency. Used as a grouping key in comparison reports.
- **Invocation Type**: Classification of how an eval case invokes the skill: explicit (direct command), implicit (natural language), or contextual (embedded in broader request).

## Success Criteria

### Measurable Outcomes

- **SC-001**: Every judge in both eval configs has a goal-category prefix, with all four categories represented in each config.
- **SC-002**: `compare-runs.sh` output clearly shows which goal category improved, regressed, or remained unchanged between two runs.
- **SC-003**: `comparison.json` is parseable and contains per-judge and per-category structured data.
- **SC-004**: Existing eval cases run without modification (backward compatible with the `explicit` default for `invocation_type`).

## Error Handling

- If `comparison.json` cannot be written (permissions, disk full), `compare-runs.sh` MUST warn to stderr but still produce the terminal table and markdown report. JSON output is best-effort.
- If a judge name contains no underscore (cannot extract a category prefix), `compare-runs.sh` MUST assign it to the "other" category and emit a warning to stderr.
- If one eval run has goal-prefixed judges and the other has legacy (unprefixed) names, the comparison MUST treat them as distinct judges. No automatic name mapping is performed.

## Assumptions

- The agent-eval-harness schema is not modified. All changes are within this plugin's eval configs and scripts.
- The harness continues to support both `check:` (deterministic) and `prompt:` (model-assisted) judge types.
- Judge naming is a convention enforced by this plugin, not by the harness. The harness treats judge names as opaque strings.
- The `skill:measure` SKILL.md references to judge names or comparison output format may need documentation updates but no logic changes.
