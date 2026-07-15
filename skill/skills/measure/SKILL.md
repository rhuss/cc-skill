---
name: "skill:measure"
description: "Run a baseline-enhance-reeval loop on a SKILL.md to measure improvement. Generates targeted test cases for enhanced patterns to ensure the comparison reflects actual improvement in changed areas. Use when testing whether skill:enhance actually improves eval scores, measuring skill quality before and after changes, or automating the measure-enhance-measure workflow. Do NOT use for evaluation only (use /eval-run instead), for enhancement only (use skill:enhance instead), or for setting up eval infrastructure (use /eval-analyze and /eval-dataset instead)."
argument-hint: "[path/to/SKILL.md]"
user-invocable: true
---

# Measure-Enhance-Measure

Orchestrate a baseline evaluation, skill enhancement, re-evaluation, and comparison in a single session. This skill invokes three other skills in sequence and then runs a comparison script to produce a delta report.

The workflow:
1. Run `/eval-run` to capture preliminary baseline scores
2. Run `/skill:enhance` to improve the skill
3. Parse the enhancement diff and generate targeted test cases for uncovered patterns (Steps 4a-4d)
4. Re-run baseline with original skill against the combined dataset, then review targeted cases (Steps 4e-4f)
5. Run `/eval-run` again with enhanced skill against the combined dataset
6. Run `compare-runs.sh` to compute and display deltas

All invocations happen within the current Claude Code session. Nested `claude -p` sessions would lose conversation context needed to capture run directory paths between steps.

## Procedure

### Step 1: Obtain the SKILL.md File

Determine the target SKILL.md file from one of these sources, checked in order:

1. **Argument path**: The user provides a path after the command (e.g., `/skill:measure path/to/SKILL.md`).
2. **Conversation context**: If no argument was given, look for the most recently referenced SKILL.md file in the conversation.

Once you have a candidate path:

- Read the file using the Read tool.
- Confirm the file contains YAML frontmatter (delimited by `---` lines at the top).
- Confirm the frontmatter includes both a `name` and a `description` field.

If validation fails, return the appropriate error from the Error Handling section and stop.

Store the validated path as `SKILL_PATH` for the remaining steps. Also save the file's current content as `ORIGINAL_SKILL_CONTENT` so it can be restored later if needed for re-running the baseline eval against a combined dataset.

### Step 2: Check Prerequisites

Before starting the loop, verify that evaluation infrastructure exists. Running eval without eval.yaml would produce a confusing error mid-loop after the user has already waited for the first eval to complete.

1. Determine the skill's directory from `SKILL_PATH` (the directory containing the SKILL.md file).
2. Search for an `eval.yaml` file. Check these locations in order:
   - Same directory as SKILL.md
   - Parent directory of SKILL.md
   - The `eval/` directory at the project root
   - Use Bash `find` from the project root if the above don't match

If no `eval.yaml` is found:

```
**Prerequisite missing**: No eval.yaml found for this skill.

Run `/eval-analyze` first to generate evaluation configuration, then `/eval-dataset` to create test cases.
```

Stop. Do not proceed without eval infrastructure.

### Step 3: Run Baseline Evaluation

Invoke `/eval-run` to evaluate the skill in its current state. This preliminary baseline verifies that eval infrastructure works and captures initial scores. If targeted cases are generated later (Steps 4a-4d), this baseline will be re-run against the combined dataset to ensure a fair comparison (see Step 4f).

After the eval completes, capture the run directory path from the conversation output. The eval-run skill reports the path to results including `summary.yaml` and `report.html`. Extract and store this path as `BASELINE_RUN_DIR`. Do not hardcode a default run directory path, because the eval harness may be configured with a custom `$AGENT_EVAL_RUNS_DIR`.

If eval-run fails or produces no results, report the failure and stop:

```
**Baseline evaluation failed**: [error details]

The measure loop cannot continue without baseline scores.
```

### Step 4: Enhance the Skill

Invoke `/skill:enhance SKILL_PATH` to improve the skill against the 17 authoring patterns.

Watch for the "already optimal" signal. If skill:enhance reports that all applicable patterns are already strong and no changes were made:

```
## Measure Result

**Skill**: `SKILL_PATH`
**Outcome**: No enhancement needed

skill:enhance reports all applicable patterns are already strong. The baseline evaluation scores represent the skill's current quality level.

**Baseline run**: `BASELINE_RUN_DIR`
```

Stop. Skip Steps 4a-4f (no enhancement diff to parse, no targeted cases to generate or review) and re-evaluation, since an identical skill would produce identical scores.

If skill:enhance produces an enhanced version and the user applies it, proceed to Step 4a.

If skill:enhance produces an enhanced version but the user skips it, report:

```
## Measure Result

**Skill**: `SKILL_PATH`
**Outcome**: Enhancement skipped by user

The baseline evaluation completed but no enhancement was applied, so re-evaluation was skipped.

**Baseline run**: `BASELINE_RUN_DIR`
```

Stop.

### Step 4a: Parse Enhancement Diff

After the enhancement is applied, extract the structured diff from the `/skill:enhance` conversation output. The enhancer produces two markdown tables in its Step 9c output:

1. **"What Changed" table** with columns: `Pattern Applied | What was added/changed | Why`
2. **"Status Change" table** with columns: `Pattern | Before | After`

Parse both tables from the conversation output:

1. Locate the "What Changed" table. For each row, extract:
   - `pattern_name` from the "Pattern Applied" column
   - `change_description` from the "What was added/changed" column

2. Locate the "Status Change" table. For each row, extract:
   - `pattern_name` from the "Pattern" column
   - `before_status` and `after_status` from the "Before" and "After" columns

3. Cross-reference the two tables: only keep patterns where `before_status != after_status` (the pattern genuinely changed status, not just had minor rewording).

4. Store the filtered list as `ENHANCEMENT_DIFF`. Each entry has `pattern_name` and `change_description`.

**Fallback**: If neither table is found in the conversation output (e.g., the output was truncated or the user applied changes manually), set `ENHANCEMENT_DIFF` to empty and warn:

```
**Note**: Could not parse enhancement diff from conversation output. Targeted case generation will be skipped. Proceeding with existing dataset only.
```

### Step 4b: Check for Existing Coverage

If `ENHANCEMENT_DIFF` is empty, skip to Step 5 (re-evaluation).

For each pattern in `ENHANCEMENT_DIFF`, check whether the existing eval dataset already covers it:

1. Scan all directories in `eval/cases/` for `annotations.yaml` files.
2. For each entry in `ENHANCEMENT_DIFF`, check both:
   - Whether any `annotations.yaml` has a `targets_pattern` field matching the pattern name (case-insensitive)
   - Whether any case directory name contains the pattern slug (the pattern name lowercased with spaces replaced by hyphens, e.g., "Known Gotchas" becomes `known-gotchas`)
3. Remove already-covered patterns from `ENHANCEMENT_DIFF`.
4. Store the filtered list as `UNCOVERED_PATTERNS`. Each entry retains both `pattern_name` and `change_description` from the original `ENHANCEMENT_DIFF` entry.

If `UNCOVERED_PATTERNS` is empty after filtering, all enhanced patterns are already covered by existing cases. Skip to Step 5 with a note:

```
All enhanced patterns are already covered by existing test cases. Proceeding with re-evaluation using the existing dataset.
```

### Step 4c: Generate Targeted Cases

If `UNCOVERED_PATTERNS` is empty, skip to Step 5.

Read `targeted_cases_per_pattern` from `eval.yaml` under the `dataset` section. If the field is absent, default to 1. Cap the value at 2 regardless of what is configured (to bound the cost of case generation).

For each pattern in `UNCOVERED_PATTERNS`, generate targeted test cases:

1. Determine the next case number. Initialize a running counter `NEXT_CASE_NUM` by finding the highest existing `NNN` in `eval/cases/case-NNN-*/` directory names and adding 1. Increment this counter after each successfully created case to avoid numbering collisions when generating multiple cases.
2. Convert the pattern name to a slug: lowercase, replace spaces with hyphens, strip all characters except `[a-z0-9-]` (e.g., "Known Gotchas" becomes `known-gotchas`).
3. The target directory name is `case-NNN-targeted-<pattern-slug>` (e.g., `case-006-targeted-known-gotchas`).
4. Invoke `/eval-dataset` with context explaining:
   - Which specific pattern to target (pattern name and the change description from `ENHANCEMENT_DIFF`)
   - That the generated case should create a synthetic SKILL.md intentionally weak in the targeted pattern area, so the checker can detect the absence
   - That the case directory must follow the naming convention above
   - That `annotations.yaml` must include a `targets_pattern` field with the pattern name
5. Repeat for up to `targeted_cases_per_pattern` cases per pattern.
6. After each invocation, verify the case directory was created and contains `input.yaml`, `target-skill/SKILL.md`, and `annotations.yaml`. Also read `annotations.yaml` and confirm it contains a `targets_pattern` field matching the intended pattern name (case-insensitive). If validation fails, count the case as a failed pattern.

Track results:
- `TARGETED_CASES`: list of successfully generated case directories
- `FAILED_PATTERNS`: list of patterns where generation failed (with reason)

**Fallback**: If `/eval-dataset` is not available (the agent-eval-harness plugin is not loaded), skip generation with a warning and set `TARGETED_CASES` to empty:

```
**Warning**: `/eval-dataset` is not available. Targeted case generation skipped. Proceeding with existing dataset only.
```

### Step 4d: Merge Targeted Cases

If `TARGETED_CASES` is empty (nothing was generated), skip to Step 5.

Confirm that all generated cases are present in `eval/cases/`:

1. List the directories in `eval/cases/` and verify each entry in `TARGETED_CASES` exists.
2. Count the total number of cases: original cases + targeted cases.
3. Store the count as `TOTAL_CASE_COUNT`.

The eval harness automatically discovers all case directories in `eval/cases/`, so no explicit registration is needed.

### Step 4e: Re-run Baseline Against Combined Dataset

If `TARGETED_CASES` is empty (no new cases generated), skip to Step 4f. The preliminary baseline from Step 3 is sufficient since the dataset has not changed.

To ensure both baseline and enhanced evals use the same combined dataset (FR-004), re-run the baseline evaluation with the original skill:

1. Save the current (enhanced) SKILL.md content as `ENHANCED_SKILL_CONTENT`.
2. Write `ORIGINAL_SKILL_CONTENT` (saved in Step 1) back to `SKILL_PATH`.
3. Invoke `/eval-run` to evaluate the original skill against the combined dataset (original + targeted cases).
4. Capture the run directory as `BASELINE_RUN_DIR`, replacing the preliminary baseline from Step 3.
5. Restore the enhanced skill by writing `ENHANCED_SKILL_CONTENT` back to `SKILL_PATH`.

If this eval fails, fall back to the preliminary baseline from Step 3 with a warning that the comparison may be imprecise because the baseline used only the original dataset.

### Step 4f: Review Targeted Cases

If `TARGETED_CASES` is empty, skip to Step 5.

Before running the eval, present the generated cases for review. Display a summary table:

```
| # | Case Directory | Targets Pattern | Input Synopsis |
|---|----------------|----------------|----------------|
| 1 | case-006-targeted-known-gotchas | Known Gotchas | [brief description from annotations.yaml] |
| 2 | case-007-targeted-template-scaffold | Template Scaffold | [brief description from annotations.yaml] |
```

If `FAILED_PATTERNS` is non-empty, add a warning row for each:

```
| - | (generation failed) | [pattern name] | **Warning**: case generation failed |
```

Prompt the user:

```
Proceed with eval? (y/n/edit)
```

Handle responses:

- **y** (or "yes", "proceed", "continue"): Continue to Step 5 with all generated cases.
- **n** (or "no", "abort", "skip"): Delete all generated targeted case directories from `eval/cases/` and continue to Step 5 with the original dataset only. Set `TARGETED_CASES` to empty and store `REVIEW_OUTCOME` as "rejected".
- **edit**: Tell the user to modify the generated cases on disk as needed, then ask "Ready to proceed? (y/n)" when they confirm. Store `REVIEW_OUTCOME` as "edited".

If the user chose "y" without modification, store `REVIEW_OUTCOME` as "approved".

### Step 5: Run Re-Evaluation

Invoke `/eval-run` again to evaluate the enhanced skill. The eval now runs against the combined dataset (original cases plus any targeted cases generated in Steps 4c-4d). The eval harness automatically picks up all cases in `eval/cases/` including newly generated targeted cases.

Capture the run directory path as `ENHANCED_RUN_DIR`, the same way as in Step 3.

If eval-run fails, report what completed:

```
**Re-evaluation failed**: [error details]

Completed steps:
- Baseline evaluation: BASELINE_RUN_DIR
- Skill enhancement: Applied

The comparison cannot run without re-evaluation scores. You can run `/eval-run` manually and then compare with:
`scripts/compare-runs.sh BASELINE_RUN_DIR <new-run-dir>`
```

### Step 6: Compare Results

Run the comparison script via Bash. Use absolute paths for both run directories to avoid issues when the working directory differs from where the eval ran:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/compare-runs.sh "BASELINE_RUN_DIR" "ENHANCED_RUN_DIR"
```

The script prints a terminal table (grouped by goal category: Outcome, Process, Style, Efficiency) to stdout, saves a detailed markdown report to `ENHANCED_RUN_DIR/comparison.md`, and emits structured data to `ENHANCED_RUN_DIR/comparison.json`.

Present the comparison output to the user. If the report shows regressions, highlight them. Regressions do not necessarily mean the enhancement was bad: some judges may score lower because the enhanced skill changed structure (e.g., reordering sections) even when the content improved.

```
**Note**: Some judges regressed after enhancement. Review the comparison report for details.
```

### Step 7: Summary

After the comparison, present a final summary:

```
## Measure-Enhance-Measure Complete

**Skill**: `SKILL_PATH`
**Baseline run**: `BASELINE_RUN_DIR`
**Enhanced run**: `ENHANCED_RUN_DIR`
**Comparison report**: `ENHANCED_RUN_DIR/comparison.md`
**Comparison data**: `ENHANCED_RUN_DIR/comparison.json`
**Targeted cases**: N generated for [pattern list]

[Summary line from compare-runs.sh output: N improved, N regressed, N unchanged]
```

If `TARGETED_CASES` is non-empty, replace `N` with the count and `[pattern list]` with the comma-separated pattern names. If `FAILED_PATTERNS` is non-empty, append:

```
**Warning**: Targeted case generation failed for: [failed pattern list]
```

If `REVIEW_OUTCOME` is set, append to the summary:

- "approved": `**Review**: Targeted cases approved`
- "rejected": `**Review**: Targeted cases rejected (eval ran against original dataset only)`
- "edited": `**Review**: Targeted cases edited by user before eval`

If no targeted cases were generated (empty `ENHANCEMENT_DIFF` or all patterns already covered), omit the "Targeted cases" and "Review" lines entirely.

## Error Handling

| Condition | Response |
|-----------|----------|
| No path provided and no SKILL.md in conversation | Return: "**Error**: No SKILL.md file specified. Provide a path as an argument (e.g., `/skill:measure path/to/SKILL.md`) or reference a SKILL.md file in the conversation first." Stop. |
| File not found | Return: "**Error**: File not found: `<path>`. Please provide a valid path to a SKILL.md file." Stop. |
| File has no YAML frontmatter or missing required fields | Return: "**Error**: `<path>` does not appear to be a valid SKILL.md file. Expected YAML frontmatter with `name` and `description` fields." Stop. |
| No eval.yaml found | Direct user to run `/eval-analyze` first (see Step 2). Stop. |
| Baseline eval fails | Report failure with details (see Step 3). Stop. |
| Enhancement reports already optimal | Report baseline scores, skip re-eval (see Step 4). Stop. |
| User skips enhancement | Report baseline scores, skip re-eval (see Step 4). Stop. |
| Re-evaluation fails | Report completed steps and manual recovery command (see Step 5). Stop. |
| Enhancement diff table not found in output | Warn that targeted case generation will be skipped. Set `ENHANCEMENT_DIFF` to empty. Proceed with existing dataset only (see Step 4a). |
| `/eval-dataset` skill not available | Warn that targeted case generation is skipped. Set `TARGETED_CASES` to empty. Proceed with existing dataset only (see Step 4c). |
| Partial case generation failure | Proceed with successfully generated cases. List failed patterns in the review prompt and final summary (see Steps 4c, 4f, 7). |
| compare-runs.sh not found | Return: "**Error**: Comparison script not found at `${CLAUDE_PLUGIN_ROOT}/scripts/compare-runs.sh`. Verify the plugin installation." Stop. |
| compare-runs.sh fails | Return script's stderr and suggest running it manually with the two run directory paths. |
