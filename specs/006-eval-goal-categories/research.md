# Research: Eval Goal Categories

## Judge Category Mapping Analysis

### Decision: Prefix-based categorization via first-underscore split

**Rationale**: The eval harness treats judge names as opaque strings. Using a naming convention (prefix_rest) lets `compare-runs.sh` extract categories without harness changes. The first underscore is the delimiter because category names are single words (outcome, process, style, efficiency).

**Alternatives considered**:
- Metadata field in eval.yaml per judge: Would require harness schema changes. Rejected (plugin-only constraint).
- Separate config file mapping judges to categories: Extra file to maintain, easy to get out of sync. Rejected.
- Composite judges (one per category): Too large a rewrite, harder to debug. Rejected.

## skill-check Coverage Analysis

### Current judges (5):
- `budget_check` (builtin) -> efficiency
- `checklist_completeness` (deterministic) -> outcome
- `status_validity` (deterministic) -> outcome
- `note_specificity` (model-assisted) -> style
- `pattern_accuracy` (model-assisted) -> outcome

### Coverage gaps:
- **process**: No judge checks procedure adherence. The skill should follow a sequence: load knowledge, evaluate patterns, produce activation test. The activation test section (trigger/non-trigger scenarios) is evidence of following procedure, currently checked inside `checklist_completeness` but mixed with output completeness. Split into a dedicated `process_evaluation_sequence` judge.
- **style (second judge)**: Only `note_specificity` covers style. Add `style_summary_format` to verify the summary line format.
- **efficiency**: `budget_check` already covers this. Rename to `efficiency_budget`.

### New judges needed: 2
- `process_evaluation_sequence`: Check for activation test with trigger + non-trigger scenarios
- `style_summary_format`: Check summary line matches `N of M applicable patterns present, X strong, Y improvements suggested`

## skill-enhance Coverage Analysis

### Current judges (7):
- `budget_check` (builtin) -> efficiency
- `output_completeness` (deterministic) -> outcome
- `pattern_evaluation` (deterministic) -> outcome
- `frontmatter_preserved` (deterministic) -> outcome
- `changelog_specificity` (model-assisted) -> style
- `proportionality` (model-assisted) -> style
- `intent_preservation` (model-assisted) -> outcome

### Coverage gaps:
- **process**: No judge checks step execution order. The enhancer has a documented 9-step procedure. The "Steps Executed" section in output is evidence of procedure adherence. Add `process_step_execution`.
- **efficiency**: `budget_check` covers this. Rename to `efficiency_budget`.

### New judges needed: 1
- `process_step_execution`: Check for "Steps Executed" section presence

## compare-runs.sh JSON Schema

### Decision: Flat structure with judges, categories, and summary at top level

```json
{
  "baseline_run_id": "string",
  "enhanced_run_id": "string",
  "baseline_dir": "string",
  "enhanced_dir": "string",
  "judges": {
    "<judge_name>": {
      "baseline": 0.0,
      "enhanced": 0.0,
      "delta": 0.0,
      "direction": "up|down|same|na",
      "category": "outcome|process|style|efficiency|other"
    }
  },
  "categories": {
    "<category>": {
      "judges": ["judge1", "judge2"],
      "direction": "Improved|Regressed|Unchanged|Mixed",
      "improved": 0,
      "regressed": 0,
      "unchanged": 0
    }
  },
  "summary": {
    "improved": 0,
    "regressed": 0,
    "unchanged": 0,
    "na": 0,
    "total": 0
  },
  "generated_at": "ISO8601"
}
```

**Rationale**: Mirrors the markdown report structure. `categories` provides the grouped view, `judges` provides the detailed view. `summary` is the same counts already computed. The `category` field on each judge enables filtering without re-parsing names.

## Invocation Type Annotations

### Decision: Add field to existing annotations.yaml, default to explicit

All 10 existing cases are explicit invocations (they pass `skill_path` directly). Adding `invocation_type: explicit` makes this explicit rather than relying on convention.

The `by_invocation_type` section in comparison.json requires per-case judge results from summary.yaml. The current harness summary.yaml structure reports aggregate scores per judge, not per-case. Therefore `by_invocation_type` breakdowns will only be possible when the harness adds per-case reporting. For now, the field is added to annotations for documentation and future use, and `comparison.json` includes the section only when per-case data is available.
