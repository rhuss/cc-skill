---
name: "skill:measure"
description: "Run a baseline-enhance-reeval loop on a SKILL.md to measure improvement. Use when testing whether skill:enhance actually improves eval scores, measuring skill quality before and after changes, or automating the measure-enhance-measure workflow. Do NOT use for evaluation only (use /eval-run instead), for enhancement only (use skill:enhance instead), or for setting up eval infrastructure (use /eval-analyze and /eval-dataset instead)."
argument-hint: "[path/to/SKILL.md]"
user-invocable: true
---

# Measure-Enhance-Measure

Orchestrate a baseline evaluation, skill enhancement, re-evaluation, and comparison in a single session. This skill invokes three other skills in sequence and then runs a comparison script to produce a delta report.

The workflow:
1. Run `/eval-run` to capture baseline scores
2. Run `/skill:enhance` to improve the skill
3. Run `/eval-run` again to capture enhanced scores
4. Run `compare-runs.sh` to compute and display deltas

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

Store the validated path as `SKILL_PATH` for the remaining steps.

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

Invoke `/eval-run` to evaluate the skill in its current state.

After the eval completes, capture the run directory path from the conversation output. The eval-run skill reports the path to results including `summary.yaml` and `report.html`. Extract and store this path as `BASELINE_RUN_DIR`. Do not hardcode a default run directory path, because the eval harness may be configured with a custom `$AGENT_EVAL_RUNS_DIR`.

If eval-run fails or produces no results, report the failure and stop:

```
**Baseline evaluation failed**: [error details]

The measure loop cannot continue without baseline scores.
```

### Step 4: Enhance the Skill

Invoke `/skill:enhance SKILL_PATH` to improve the skill against the 14 authoring patterns.

Watch for the "already optimal" signal. If skill:enhance reports that all applicable patterns are already strong and no changes were made:

```
## Measure Result

**Skill**: `SKILL_PATH`
**Outcome**: No enhancement needed

skill:enhance reports all applicable patterns are already strong. The baseline evaluation scores represent the skill's current quality level.

**Baseline run**: `BASELINE_RUN_DIR`
```

Stop. Skip re-evaluation since an identical skill would produce identical scores.

If skill:enhance produces an enhanced version and the user applies it, proceed to Step 5.

If skill:enhance produces an enhanced version but the user skips it, report:

```
## Measure Result

**Skill**: `SKILL_PATH`
**Outcome**: Enhancement skipped by user

The baseline evaluation completed but no enhancement was applied, so re-evaluation was skipped.

**Baseline run**: `BASELINE_RUN_DIR`
```

Stop.

### Step 5: Run Re-Evaluation

Invoke `/eval-run` again to evaluate the enhanced skill.

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

The script prints a terminal table to stdout and saves a detailed markdown report to `ENHANCED_RUN_DIR/comparison.md`.

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

[Summary line from compare-runs.sh output: N improved, N regressed, N unchanged]
```

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
| compare-runs.sh not found | Return: "**Error**: Comparison script not found at `${CLAUDE_PLUGIN_ROOT}/scripts/compare-runs.sh`. Verify the plugin installation." Stop. |
| compare-runs.sh fails | Return script's stderr and suggest running it manually with the two run directory paths. |
