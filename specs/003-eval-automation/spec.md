# Feature Specification: Measure-Enhance-Measure Automation

**Feature Branch**: `003-eval-automation`
**Created**: 2026-05-27
**Status**: Draft
**Input**: User description: "Build automation tooling for the measure-enhance-measure workflow with a skill for orchestration and a script for comparison."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Run the Full Enhance Loop (Priority: P1)

A skill author has already set up evaluation for their skill (eval.yaml and dataset exist via `/eval-analyze` and `/eval-dataset`). They want to measure their skill's baseline quality, enhance it, and measure again in a single command rather than running 4 separate steps manually.

**Why this priority**: This is the core automation value. Without it, users must manually invoke eval-run, skill:enhance, and eval-run again, then figure out what changed.

**Independent Test**: Can be fully tested by running `/skill:measure path/to/SKILL.md` on a skill that has eval.yaml and a dataset configured. Delivers baseline scores, an enhanced skill, re-evaluation scores, and a comparison report.

**Acceptance Scenarios**:

1. **Given** a skill with eval.yaml and dataset already configured, **When** the user runs `/skill:measure path/to/SKILL.md`, **Then** the system runs a baseline evaluation, enhances the skill, runs a second evaluation, and presents a comparison report.
2. **Given** a skill where `/skill:enhance` reports "already optimal" (all patterns strong), **When** the user runs `/skill:measure`, **Then** the system reports that no enhancement was needed and skips the re-evaluation step.
3. **Given** a skill with no eval.yaml configured, **When** the user runs `/skill:measure`, **Then** the system reports the prerequisite is missing and directs the user to run `/eval-analyze` first.

---

### User Story 2 - Compare Any Two Eval Runs (Priority: P2)

A user wants to compare the results of two eval runs, whether from the automated loop or from separate manual runs. They run the comparison script directly and get a clear delta report showing what improved and what regressed.

**Why this priority**: The comparison is the most painful manual step. Making it standalone means it's useful beyond just the enhance loop (e.g., comparing runs across different models, or across manual skill edits).

**Independent Test**: Can be tested by running `scripts/compare-runs.sh <run-dir-1> <run-dir-2>` with two existing eval run directories. Delivers a terminal table and a markdown report file.

**Acceptance Scenarios**:

1. **Given** two eval run directories each containing a summary.yaml, **When** the user runs the comparison script with both paths, **Then** the script prints a summary table to the terminal showing per-judge score deltas.
2. **Given** two eval run directories, **When** the user runs the comparison script, **Then** the script saves a detailed markdown report file in a predictable location.
3. **Given** a run directory missing summary.yaml, **When** the user runs the comparison script, **Then** the script exits with a clear error message identifying which directory is missing the file.
4. **Given** two runs with different judge sets (e.g., one run has a judge the other doesn't), **When** the user runs the comparison script, **Then** judges present in only one run are shown with "N/A" for the missing side.

---

### User Story 3 - Review the Comparison Report (Priority: P3)

A user who ran `/skill:measure` or the comparison script wants to understand the results. They read the markdown report to see which judges improved, which regressed, and by how much.

**Why this priority**: The report is the primary output users interact with. It must be clear and actionable.

**Independent Test**: Can be tested by reading a generated comparison report and verifying it contains per-judge deltas, an overall summary, and clear improvement/regression indicators.

**Acceptance Scenarios**:

1. **Given** a comparison report, **When** the user reads the summary section, **Then** they see the total number of judges that improved, regressed, and stayed the same.
2. **Given** a comparison report, **When** the user reads the per-judge details, **Then** each judge shows its baseline score, enhanced score, and delta with a directional indicator (improvement or regression).
3. **Given** a comparison where some judges improved and some regressed, **When** the user reads the report, **Then** regressions are clearly highlighted so they are not missed.

---

### Edge Cases

- What happens when the eval run produces no scores (e.g., all test cases failed)? The comparison should handle zero-score runs gracefully with a clear message.
- What happens when the user interrupts the enhance loop mid-way (e.g., after baseline but before enhancement)? The skill should report what completed and what remains.
- What happens when the skill being measured is the same as one of cc-skill's own skills? This should work normally since the workflow is generic.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The plugin MUST provide a new `skill:measure` skill that orchestrates the baseline-enhance-reeval loop within a single Claude Code session.
- **FR-002**: `skill:measure` MUST invoke `/eval-run` for the baseline evaluation, `/skill:enhance` for skill improvement, and `/eval-run` again for re-evaluation, in that order.
- **FR-003**: `skill:measure` MUST call the comparison script after both eval runs complete and present the delta report to the user.
- **FR-004**: `skill:measure` MUST detect when no eval.yaml exists and direct the user to run `/eval-analyze` first.
- **FR-005**: `skill:measure` MUST detect when `/skill:enhance` reports the skill is already optimal and skip the re-evaluation step.
- **FR-006**: The plugin MUST provide a `scripts/compare-runs.sh` script that compares two eval run directories.
- **FR-007**: `compare-runs.sh` MUST read `summary.yaml` from both run directories and compute per-judge score deltas.
- **FR-008**: `compare-runs.sh` MUST print a summary table to the terminal (stdout).
- **FR-009**: `compare-runs.sh` MUST save a detailed markdown comparison report file next to the second (enhanced) run directory as `comparison.md`.
- **FR-010**: `compare-runs.sh` MUST be callable standalone, independent of the `skill:measure` skill.
- **FR-011**: `compare-runs.sh` MUST handle mismatched judge sets between runs (showing N/A for judges present in only one run).
- **FR-012**: `compare-runs.sh` MUST exit with a clear error if either run directory is missing summary.yaml.
- **FR-013**: `skill:measure` MUST NOT use nested `claude -p` sessions. All skill invocations happen within the same Claude Code session.
- **FR-014**: `skill:measure` MUST capture eval run directory paths from `/eval-run`'s conversation output (not from a hardcoded default location).

### Key Entities

- **Eval Run**: A directory containing evaluation results, including `summary.yaml` with per-judge scores.
- **Summary YAML**: A structured file produced by `/eval-run` containing judge names, score types (numeric mean or boolean pass_rate), and aggregate scores.
- **Comparison Report**: A markdown document showing per-judge deltas between two eval runs, with improvement/regression indicators and an overall summary.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can measure, enhance, and compare a skill's quality in a single `/skill:measure` invocation instead of 4 manual steps.
- **SC-002**: The comparison report shows per-judge deltas for 100% of judges present in either run.
- **SC-003**: The comparison script completes in under 5 seconds for runs with up to 20 judges.
- **SC-004**: Users can compare any two eval runs standalone via the comparison script without needing the skill.

## Clarifications

### Session 2026-05-27

- Q: Where should the comparison report file be saved? → A: Next to the second (enhanced) run directory as `comparison.md`
- Q: How does skill:measure locate eval run output directories? → A: Captures the run directory path from `/eval-run`'s conversation output

## Assumptions

- Both the cc-skill plugin and agent-eval-harness plugin are installed and functional.
- The user has already run `/eval-analyze` and `/eval-dataset` to set up evaluation for their skill before invoking `/skill:measure`.
- The eval-harness stores run results in directories containing `summary.yaml` files.
- The `summary.yaml` format includes judge names and aggregate scores (either numeric `mean` or boolean `pass_rate`).
- `yq` is available on the user's system for YAML parsing in the comparison script.
