# Implementation Plan: Targeted Eval Dataset for Enhancement Coverage

**Branch**: `004-targeted-eval-dataset` | **Date**: 2026-05-31 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/004-targeted-eval-dataset/spec.md`

## Summary

Extend `/skill:measure` to analyze the enhancement diff (the "What Changed" table from `/skill:enhance`), generate targeted test cases for enhanced patterns not already covered by the existing dataset, present them for interactive review, merge approved cases into `eval/cases/`, and run both baseline and enhanced evals against the combined dataset. This ensures the comparison reflects actual improvement in enhanced areas rather than only measuring pre-existing coverage.

## Technical Context

**Language/Version**: Bash (scripts), Markdown (SKILL.md skill definitions)
**Primary Dependencies**: agent-eval-harness plugin (`/eval-run`, `/eval-dataset`), yq (YAML parsing), skill plugin (`/skill:enhance`, `/skill:check`)
**Storage**: File-based eval case directories (`eval/cases/`)
**Testing**: Manual testing against real SKILL.md files with eval infrastructure
**Target Platform**: macOS/Linux (Claude Code environments)
**Project Type**: Claude Code plugin (skill modification + supporting logic)
**Performance Goals**: Targeted case generation adds no more than 30 seconds to the `/skill:measure` workflow (SC-003)
**Constraints**: No nested `claude -p` sessions; all invocations within current session; must not modify existing test cases (FR-007)
**Scale/Scope**: 1-2 targeted cases per enhanced pattern; bounded by `targeted_cases_per_pattern` in `eval.yaml`

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Constitution is a blank template. No gates to evaluate. Passes by default.

## Project Structure

### Documentation (this feature)

```text
specs/004-targeted-eval-dataset/
├── spec.md              # Feature specification
├── plan.md              # This file
├── research.md          # Phase 0: enhancement diff format, eval-dataset integration
├── data-model.md        # Phase 1: entity definitions
└── tasks.md             # Phase 2 output (created by /speckit-tasks)
```

### Source Code (repository root)

```text
skill/
├── skills/
│   └── measure/
│       └── SKILL.md           # MODIFIED: add targeted case generation steps
└── scripts/
    └── compare-runs.sh        # Existing (no changes needed)

eval.yaml                      # MODIFIED: add targeted_cases_per_pattern config
```

**Structure Decision**: This feature modifies one existing file (`skill/skills/measure/SKILL.md`) and one config file (`eval.yaml`). No new files or directories are created in the source tree. The targeted case generation logic is embedded in the skill's procedure steps, not extracted into a separate script, because the generation relies on LLM capabilities (understanding which patterns were enhanced and what test inputs would exercise them).

## Design Decisions

### D1: Enhancement Diff Capture

The enhancement diff is captured by parsing the "What Changed" markdown table that `/skill:enhance` outputs in Step 9c. This table has the structure:

```markdown
| Pattern Applied | What was added/changed | Why |
|----------------|----------------------|-----|
| Known Gotchas  | Added specific YAML validation pitfall | Domain has non-obvious failure modes |
```

After `/skill:enhance` completes (and the user applies changes), `/skill:measure` parses this table from the conversation output to extract:
- Pattern names from the "Pattern Applied" column
- Change descriptions from the "What was added/changed" column

This is the same approach used for detecting "already optimal" (reading conversation output for signals). No structured data file is needed because the table is well-formatted and parseable.

**Edge case**: If the table is absent (user applied changes manually or output was truncated), treat as "unknown diff" and fall back to existing dataset only with a warning.

### D2: Targeted Case Generation

For each pattern in the enhancement diff, `/skill:measure` generates targeted test cases by:

1. Checking if an existing case in `eval/cases/` already targets this pattern (name-based matching on directory names and `annotations.yaml` content)
2. If not covered, invoking `/eval-dataset` with a hint about which pattern to target
3. Each generated case follows the existing case directory structure:
   ```
   eval/cases/case-NNN-targeted-<pattern-slug>/
   ├── input.yaml         # skill_path pointing to a synthetic SKILL.md
   ├── target-skill/
   │   └── SKILL.md       # Synthetic skill designed to exercise the pattern
   └── annotations.yaml   # Expected outcomes with targets_pattern metadata
   ```

The `annotations.yaml` includes a `targets_pattern` field for traceability:
```yaml
description: "Tests gotcha handling added by enhancement"
targets_pattern: "Known Gotchas"
```

### D3: Deduplication Strategy

Before generating a case for an enhanced pattern, check existing cases:

1. Scan all directories in `eval/cases/` for `annotations.yaml` files
2. Check if any existing annotation has a `targets_pattern` field matching the pattern name
3. Also check if the directory name contains the pattern slug (e.g., `case-*-known-gotchas`)
4. Skip generation for patterns already covered

This is intentionally simple (string matching, not semantic analysis) to keep the workflow fast and deterministic.

### D4: Interactive Review Flow

After generating targeted cases (and before any eval run), `/skill:measure` presents a review prompt:

1. Display a summary table of generated cases:
   ```
   | # | Case Directory | Targets Pattern | Input Synopsis |
   |---|----------------|----------------|----------------|
   | 1 | case-006-targeted-known-gotchas | Known Gotchas | YAML validation skill missing pitfall coverage |
   ```

2. Prompt: "Proceed with eval? (y/n/edit)"
   - **y**: Continue with all generated cases
   - **n**: Abort, remove generated cases, run with original dataset only
   - **edit**: User modifies cases on disk, then confirms to continue

3. If partial generation failure occurred, the summary includes a warning row for each failed pattern

### D5: Workflow Integration

The modified `/skill:measure` procedure becomes:

1. Obtain SKILL.md file (existing Step 1)
2. Check prerequisites (existing Step 2)
3. Run baseline evaluation (existing Step 3)
4. Enhance the skill (existing Step 4)
5. **NEW: Parse enhancement diff** from Step 4's output
6. **NEW: Generate targeted cases** for uncovered enhanced patterns
7. **NEW: Interactive review** of generated cases
8. **NEW: Merge approved cases** into eval/cases/
9. Run re-evaluation against combined dataset (modified Step 5)
10. Compare results (existing Step 6)
11. **NEW: Report targeted case info** in summary (modified Step 7)

Steps 5-8 are inserted between the existing Steps 4 and 5. They are skipped entirely when the enhancer reports "already optimal" (no diff to parse).

### D6: eval.yaml Configuration

Add a `targeted_cases_per_pattern` field to the eval.yaml schema:

```yaml
# Existing fields...
dataset:
  path: eval/cases
  targeted_cases_per_pattern: 1  # NEW: default 1, max 2
```

This field controls how many test cases are generated per enhanced pattern. Default is 1 if the field is absent.

### D7: Partial Failure Handling

If targeted case generation fails for some patterns:
- Successfully generated cases are kept
- Failed patterns are listed in the review prompt with a warning
- The user can still proceed with the successfully generated cases
- The final summary reports both successful and failed targeted case counts

## Complexity Tracking

No constitution violations to justify. The feature adds 5 new steps to an existing 7-step skill and one new config field. No new files, no new abstractions.
