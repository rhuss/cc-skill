# Implementation Plan: Measure-Enhance-Measure Automation

**Branch**: `003-eval-automation` | **Date**: 2026-05-27 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/003-eval-automation/spec.md`

## Summary

Add a `skill:measure` skill and a `scripts/compare-runs.sh` script to cc-skill. The skill orchestrates the baseline-enhance-reeval loop within a single Claude Code session. The script computes deterministic comparison deltas between two eval runs, producing both terminal output and a markdown report.

## Technical Context

**Language/Version**: Bash (script), Markdown (SKILL.md)
**Primary Dependencies**: yq (YAML parsing), agent-eval-harness plugin (eval-run skill)
**Storage**: N/A (reads existing eval run directories)
**Testing**: Manual testing against real eval runs
**Target Platform**: macOS/Linux (Claude Code environments)
**Project Type**: Claude Code plugin (new skill + utility script)
**Constraints**: No nested claude -p sessions (FR-013), script must be standalone (FR-010)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Constitution is a blank template. No gates to evaluate. Passes by default.

## Project Structure

### Documentation (this feature)

```text
specs/003-eval-automation/
├── spec.md              # Feature specification
├── plan.md              # This file
├── research.md          # Phase 0: summary.yaml format, scoring logic
└── tasks.md             # Phase 2 output (created by /speckit-tasks)
```

### Source Code (repository root)

```text
skill/
├── skills/
│   ├── checker/
│   │   └── SKILL.md           # Existing
│   ├── enhancer/
│   │   └── SKILL.md           # Existing
│   └── measure/
│       └── SKILL.md           # NEW: skill:measure orchestration skill
└── scripts/
    └── compare-runs.sh        # NEW: deterministic comparison script
```

**Structure Decision**: Two new files in the existing plugin structure. The skill goes in `skill/skills/measure/SKILL.md` following the existing pattern (checker, enhancer). The script goes in `skill/scripts/` since it's a utility bundled with the plugin.

## Design Decisions

### D1: Skill Architecture

`skill:measure` is an orchestration skill. It invokes three other skills in sequence:
1. `/eval-run` (from agent-eval-harness) for baseline
2. `/skill:enhance` (from this plugin) for enhancement
3. `/eval-run` (from agent-eval-harness) for re-evaluation

After both eval runs, it calls `scripts/compare-runs.sh` via Bash with the two run directory paths.

The skill does not duplicate any eval logic. It's pure orchestration.

### D2: Comparison Script Design

`compare-runs.sh` takes two positional arguments (run directory paths), reads `summary.yaml` from each, and:
1. Extracts all judge names from both files (union set)
2. For each judge, reads `mean` (numeric) or `pass_rate` (boolean)
3. Computes delta (enhanced - baseline)
4. Prints a formatted table to stdout
5. Writes a detailed markdown report to `<run-dir-2>/comparison.md`

Uses `yq` for YAML parsing. No Python dependency.

### D3: Already-Optimal Detection

When `/skill:enhance` reports a skill is already optimal (all patterns strong), `skill:measure` skips the re-evaluation step and reports "no enhancement needed." This avoids a wasted eval run that would produce identical scores.

The skill detects this by reading skill:enhance's conversation output for the "already optimal" signal.

### D4: Error Handling

- Missing eval.yaml: skill:measure checks for eval.yaml before starting and directs user to `/eval-analyze`
- Missing summary.yaml: compare-runs.sh validates both directories and exits with a clear error
- Mismatched judges: compare-runs.sh shows N/A for judges present in only one run
- Interrupted loop: skill:measure reports what completed (e.g., "baseline complete, enhancement failed")

### D5: summary.yaml Contract

The comparison script depends on this structure from the eval-harness:

```yaml
judges:
  judge_name:
    mean: 4.2        # float or null (numeric judges)
    pass_rate: 0.85   # float or null (boolean judges)
```

For each judge, the script uses `pass_rate` if non-null, otherwise `mean`. This handles both boolean and numeric judges uniformly.
