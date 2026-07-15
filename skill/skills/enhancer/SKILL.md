---
name: "skill:enhance"
description: "Improve a SKILL.md file by applying missing or weak skill-authoring patterns (17 patterns across 7 categories). Use when a skill needs strengthening, after running skill:check to identify gaps, or when creating a new skill from scratch. Do NOT use for prompt-level improvements (use prompt:enhance instead) or for evaluation only (use skill:check instead)."
argument-hint: "[path/to/SKILL.md]"
user-invocable: true
---

# Skill Enhancement

## Overview

This skill takes a Claude Code SKILL.md file, evaluates it against 17 skill-authoring patterns from 7 categories, and produces a rewritten version that addresses missing or weak patterns. The output includes the enhanced skill text, a changelog table explaining each pattern applied, a before/after status table, and an apply/skip choice for the user.

The enhancer preserves the original skill's intent, voice, and structure. Enhancement is proportionate to the skill's complexity (a 50-line skill should not become 400 lines).

## Procedure

### Step 1: Input Handling

Obtain the SKILL.md file path from the command argument.

1. **File path argument**: The user provides a path after the `/skill:enhance` command (e.g., `/skill:enhance path/to/SKILL.md`).
2. **Conversation context**: If no path was provided, look for the most recently referenced SKILL.md file in the conversation. Search for file paths ending in `SKILL.md` that were read, discussed, or mentioned.

**Validation** (run all three checks in order):
- Verify the file exists on disk using the Read tool.
- Verify the file is not empty (0 bytes).
- Verify the file contains YAML frontmatter (delimited by `---` lines at the top) with both `name` and `description` fields.

**Error conditions**:

| Condition | Response |
|-----------|----------|
| No path provided and no SKILL.md in conversation | Return: "**Error**: No SKILL.md file specified. Provide a path as an argument (e.g., `/skill:enhance path/to/SKILL.md`) or reference a SKILL.md file in the conversation before invoking." Stop. |
| File not found | Return: "**Error**: File not found: `<path>`. Please provide a valid path to a SKILL.md file." Stop. |
| File is empty | Return: "**Error**: The file at `<path>` is empty. A SKILL.md file requires at minimum YAML frontmatter with `name` and `description` fields." Stop. |
| No YAML frontmatter or missing name/description | Return: "**Error**: `<path>` does not appear to be a valid SKILL.md file. Expected YAML frontmatter with `name` and `description` fields." Stop. |

Store the file path as `SKILL_PATH` and the parsed content as `SKILL_CONTENT` for the remaining steps.

### Step 2: Load Knowledge

Read the skill-authoring patterns knowledge file using the Read tool:

- `${CLAUDE_PLUGIN_ROOT}/knowledge/skill-authoring-patterns.md`

This file defines all 17 patterns with detection signals, quality criteria, and improvement guidance. It is the single reference for pattern evaluation and enhancement decisions.

**Error condition**: If the knowledge file cannot be loaded, return:

```
**Error**: Could not load skill-authoring patterns from `${CLAUDE_PLUGIN_ROOT}/knowledge/skill-authoring-patterns.md`. This file is required for enhancement. Verify the plugin installation is complete.
```

Stop. Do not attempt enhancement without the knowledge file.

### Step 3: Baseline Evaluation

Evaluate `SKILL_CONTENT` against all 17 patterns from the knowledge file. This establishes the current state before enhancement.

For each pattern, assign one of four statuses:

- **strong**: The pattern is present and meets all quality criteria for "Strong" as defined in the knowledge file.
- **present**: The pattern exists but meets only the "Present" criteria, with room for improvement.
- **absent**: The pattern is applicable to this skill but not present at all.
- **N/A**: The pattern is conditional (has an applicability condition in the knowledge file) and that condition does not apply to this skill.

Evaluate patterns in order by category:

**Discovery** (patterns 1-2):
1. Activation Metadata
2. Exclusion Clause

**Context Economy** (patterns 3-4):
3. Context Budget
4. Progressive Disclosure (conditional: only applicable if skill is longer than ~200 lines or has distinct reference material)

**Instruction Calibration** (patterns 5-9):
5. Control Tuning
6. Explain-the-Why
7. Template Scaffold (conditional: only applicable if skill produces structured output)
8. In-Skill Examples (conditional: only applicable if input/output mapping is non-obvious)
9. Known Gotchas (conditional: only applicable if the domain has common pitfalls)

**Workflow Control** (patterns 10-12):
10. Execution Checklist (conditional: only applicable if skill has 3+ ordered steps)
11. Self-Correcting Loop (conditional: only applicable if skill produces artifacts requiring validation)
12. Plan-Validate-Execute (conditional: only applicable if skill modifies user files or external systems)

**Executable Code** (pattern 13):
13. Utility Bundle (conditional: only applicable if skill needs helper scripts or programmatic logic)

**Meta** (pattern 14):
14. Autonomy Calibration

**Workflow Quality** (patterns 15-17):
15. Process over Prose
16. Anticipate the Excuse (conditional: only applicable if skill has non-negotiable rules or hard constraints)
17. Stay in Scope (conditional: only applicable if skill modifies files or system state)

Record the status list as `BASELINE_STATUS`. Count applicable patterns (excluding N/A) as `APPLICABLE_COUNT`. Count strong patterns as `STRONG_COUNT`.

### Step 4: Already-Optimal Detection

If every applicable pattern has status "strong" (meaning `STRONG_COUNT` equals `APPLICABLE_COUNT`), the skill is already well-crafted.

When already optimal, return this output and stop (skip Steps 5-9):

```
## Skill Authoring Assessment

**File**: `<SKILL_PATH>`

This skill is already well-crafted. All applicable patterns are effectively applied.

### Patterns Applied Effectively

| # | Pattern | Category | Notes |
|---|---------|----------|-------|
| 1 | Activation Metadata | Discovery | [What makes it strong] |
| ... | ... | ... | ... |

No changes were made.
```

Do not force rewrites when the skill is already strong.

### Step 5: Enhancement Targeting

Using `BASELINE_STATUS`, select which patterns to address:

1. **Priority 1 (absent patterns)**: These are the primary targets. Each absent pattern represents a missing skill-authoring practice.
2. **Priority 2 (present patterns)**: These are secondary targets. The pattern exists but does not meet "strong" criteria.
3. **Skip**: Do not modify "strong" or "N/A" patterns.

For each targeted pattern, retrieve its "Improvement guidance" section from the knowledge file. This guidance directs the specific changes to make.

**Proportionality gate**: For very short skills (under ~30 lines or fewer than 5 applicable patterns), only target patterns that are clearly absent and relevant to the skill's scope. A 20-line utility does not need an Exclusion Clause, Explain-the-Why rationale for every line, or Known Gotchas unless the domain genuinely has non-obvious pitfalls. Skip conditional patterns whose applicability conditions are borderline for a skill this small. The goal is to make the skill better at what it does, not to inflate it with patterns it does not need.

**Minimum improvement threshold**: For skills with 5 or more applicable patterns that score below 70% (fewer than 70% of applicable patterns are "strong"), address at least 2 patterns. This ensures meaningful improvement rather than cosmetic changes. This threshold does not apply to skills caught by the proportionality gate above.

### Step 6: Rewrite

Produce an enhanced version of `SKILL_CONTENT` that applies the targeted patterns from Step 5.

**Rewrite rules**:

1. **Preserve intent**: The enhanced skill must perform the same task as the original. Do not change its purpose, scope, or fundamental behavior.
2. **Preserve voice**: If the skill has a distinct style or tone, maintain it while improving structure.
3. **Preserve structure**: Keep the same major sections and general flow. Improvements should refine and extend, not reorganize from scratch.
4. **Apply patterns naturally**: Integrate patterns into the text as a skilled author would. Do not add visible labels like "[Pattern: Execution Checklist]" in the output.
5. **Keep proportionate**: A simple 50-line skill should become a better 50-line skill, not a 400-line specification. Scale enhancement to the skill's complexity.
6. **Preserve all original frontmatter fields**: Keep every field from the original frontmatter. You may improve field values (e.g., sharpening the description) but do not remove fields.
7. **Preserve comments and HTML blocks**: Comments (`<!-- -->`) in the original SKILL.md are content and must be kept.

The most common enhancement mistake is changing a skill's intent while restructuring it. If you find yourself adding new workflow steps, requiring new inputs, or altering what the skill produces, you have drifted from enhancement into redesign. Compare your rewrite against the original's purpose statement before proceeding.

A second pitfall is over-enhancing simple skills. A 50-line skill that becomes 200 lines has not been improved; it has been burdened. Add only what the missing patterns require, nothing more. If a pattern can be addressed with one sentence inline, do not add an entire section. For very short skills (under ~30 lines), limit enhancements to improving the frontmatter (description, argument-hint) and at most 1-2 inline additions. A 20-line utility that becomes 60 lines has tripled in complexity for marginal benefit.

**Writing constraints**:
- No em-dashes or en-dashes. Use commas, parentheses, or separate sentences.
- Avoid vague or inflated language. Write clear, direct instructions.

**Example**: Here is a before/after for applying the Known Gotchas pattern to a skill that validates YAML files:

Before (absent):
```markdown
### Step 3: Validate Structure
Check that all required fields are present in the YAML file.
```

After (strong):
```
### Step 3: Validate Structure
Check that all required fields are present in the YAML file.

A common mistake is checking only top-level keys while ignoring nested required fields. For example, a `deploy` block might exist but lack its required `target` sub-field. Validate at every nesting level, not just the root.
```

The gotcha is placed at the instruction where the mistake would happen, names what goes wrong (checking only top-level), and says how to avoid it (validate at every nesting level).

**Enhancement strategies for patterns 15-17**:

**Process over Prose (Pattern 15)**: When the skill has descriptive prose that explains concepts without directing action, restructure those sections into numbered workflow steps with imperative verbs. Each step should have a clear action and, where applicable, an entry condition ("Before this step, verify...") and exit condition ("This step is done when..."). Preserve the original explanatory content as brief context before or within the action steps, but ensure every paragraph ends with or contains a directed action.

Before (absent):
```markdown
The skill analyzes error logs by examining patterns. Different log formats
require different parsing approaches. JSON logs can be processed directly
while plain text logs need regex matching.
```

After (present):
```markdown
### Step N: Parse Error Logs

1. Detect the log format by reading the first 5 lines. If lines are valid JSON, use JSON parsing. If not, use regex matching.
2. For JSON logs: extract the `level`, `message`, and `timestamp` fields from each entry.
3. For plain text logs: apply the regex patterns from the `patterns/` directory to extract structured fields.
4. Collect all entries with level "ERROR" or "FATAL" into the analysis set.
```

**Anticipate the Excuse (Pattern 16)**: When the skill has MUST or NEVER rules without pre-answered objections, identify each hard rule and generate a rebuttal table listing 2-3 likely rationalizations the LLM might use to skip the rule, along with explicit counters. Place the rebuttal immediately after the rule it defends.

Before (absent):
```markdown
You MUST run the test suite before committing. Never skip tests.
```

After (present):
```markdown
You MUST run the test suite before committing. Never skip tests.

| You might think... | But actually... |
|---|---|
| "The change is too small to break anything" | Small changes cause the majority of production incidents. A one-line typo in a config file took down the service for 2 hours last quarter. |
| "Tests are slow and I already checked manually" | Manual verification misses regression paths. The test suite covers 47 edge cases you will not check by hand. |
| "Tests are failing for an unrelated reason" | Keep the failure visible and fix the root cause before committing. Do not skip the failing test or the suite. |
```

**Stay in Scope (Pattern 17)**: When the skill modifies files or system state but lacks explicit scope boundaries, add a scope-bounding section with both positive constraints (what to touch) and negative constraints (what not to touch), each with rationale.

Before (absent):
```markdown
### Step 3: Apply Changes
Update the configuration files based on the analysis results.
```

After (present):
```markdown
### Step 3: Apply Changes
Update the configuration files based on the analysis results.

**Scope**: Only modify files under `config/` in the project root. Do NOT modify files outside this directory, especially `package.json` (managed by npm) or `.env` files (contain secrets that must be edited manually). The config directory constraint exists because other directories have their own update workflows that this skill would conflict with.
```

### Step 7: File Splitting (Progressive Disclosure)

After rewriting, check the line count of the enhanced SKILL.md.

**If the enhanced skill exceeds ~500 lines**, split it into multiple files:

1. Keep the core workflow in SKILL.md (the main decision-making logic, procedure steps, output format, and error handling).
2. Move supplementary content into companion files in the same directory as SKILL.md:
   - Reference tables, pattern catalogs, or lookup data go into `reference.md`
   - Example collections go into `examples.md`
   - Edge cases and pitfall lists go into `gotchas.md`
   - Use descriptive lowercase-hyphenated names for any other companion files

3. In SKILL.md, add conditional loading instructions for each companion file. Load companion files only when the skill's current execution path needs them, not unconditionally at startup.

**If the enhanced skill is under ~500 lines**, skip this step. Do not split small skills.

Record any new files created as `NEW_FILES` (list of filename and purpose pairs).

### Step 8: Prompt Plugin Delegation

Check if prompt plugin skills are available in the current session. Look for any available skill with a `prompt:` prefix that enhances SKILL.md files (e.g., `prompt:skill-enhancer`). The prompt plugin skill name may vary across installations, so match by prefix and purpose rather than exact name.

**If prompt plugin skills are available**: Note the availability for the post-apply offer in Step 9d. Do NOT invoke the prompt plugin here and do NOT ask the user about it here. The prompt plugin offer is presented as a separate question AFTER the apply/skip decision. Combining two questions into one message creates a confusing interaction.

**If prompt plugin skills are not available**: Continue to Step 9. Do not print errors, warnings, or any mention of the missing plugin. The enhancer works standalone using skill-authoring patterns when the prompt plugin is not installed.

### Step 9: Changelog and User Choice

Present the enhancement results and let the user decide whether to apply changes.

#### 9a: Step Execution Log

Before presenting results, list which steps were executed and which were skipped. Use this format:

```
### Steps Executed
- Step 1: Input Handling — completed
- Step 2: Load Knowledge — completed
- Step 3: Baseline Evaluation — completed
- Step 4: Already-Optimal Detection — not optimal, continued
- Step 5: Enhancement Targeting — completed, N targets selected
- Step 6: Rewrite — completed
- Step 7: File Splitting — skipped (under 500 lines) | completed (N files)
- Step 8: Prompt Plugin Delegation — detected (offered after apply/skip) | skipped (plugin not available)
- Step 9: Changelog — in progress
```

Every step must appear. For skipped steps, state the reason. This log forces explicit acknowledgment of each step rather than allowing silent omission.

#### 9b: Re-evaluate the Enhanced Skill

Run the same 17-pattern evaluation from Step 3 against the enhanced skill text. Record results as `ENHANCED_STATUS`.

Verify that the enhanced skill improved over the baseline. If `ENHANCED_STATUS` shows no improvement (same number or fewer "strong" patterns), revisit Step 6 and strengthen the rewrite. Retry at most once. If the second attempt still shows no improvement, present the best version and note in the summary that improvement was limited.

A pattern status that does not change between baseline and enhanced evaluation usually means the enhancement was too shallow. For example, adding a generic "be careful" warning does not move Known Gotchas from "present" to "strong." The gotcha must name a specific mistake and its mitigation.

#### 9c: Format the Output

Format the output exactly as follows:

```
### Steps Executed
[Step execution log from 9a]

## Enhanced Skill

[Full rewritten SKILL.md text, including frontmatter]

---

## What Changed

| Pattern Applied | What was added/changed | Why |
|----------------|----------------------|-----|
| [Pattern Name] | [Specific change made] | [Reasoning for this change] |
| ... | ... | ... |

## New Files (if any)

| File | Purpose |
|------|---------|
| [filename.md] | [What it contains and when it is loaded] |

## Status Change

| Pattern | Before | After |
|---------|--------|-------|
| [Pattern Name] | absent | strong |
| [Pattern Name] | present | strong |
| ... | ... | ... |

**Summary**: X patterns improved, Y new files proposed
```

**Formatting rules**:
- The "Enhanced Skill" section contains the complete rewritten SKILL.md text, ready to save to disk. Include the YAML frontmatter.
- Each row in "What Changed" describes one pattern application with a specific reference to what text was added or modified, and why (in terms of the skill's specific content, not generic pattern descriptions).
- The "New Files" section only appears if Step 7 produced companion files.
- The "Status Change" table only includes patterns whose status changed. Do not list unchanged patterns.
- The "Summary" line shows the total count of patterns that moved from absent/present to a better status, plus the number of new files if any.

#### 9d: Present the User Choice

After showing the output, present the user with a choice:

- **Apply**: Write the enhanced skill to `SKILL_PATH`, replacing the current content. If companion files were created in Step 7, write those too.
- **Skip**: Keep the original skill unchanged. Do not write any files.

**If the user selects Apply**:
1. Write the enhanced SKILL.md content to `SKILL_PATH`.
2. Write any companion files to the same directory as `SKILL_PATH`.
3. Confirm: "Updated `<SKILL_PATH>` with the enhanced skill." If companion files were written, list them.

**If the user selects Skip**:
- Confirm: "Original skill left unchanged at `<SKILL_PATH>`."

#### 9e: Prompt Plugin Follow-Up (Separate Question)

Only after the apply/skip decision is resolved, if prompt plugin skills were detected in Step 8:

Present a **separate** question (not combined with any other prompt):

```
The `prompt:skill-enhancer` plugin is available to check prompt-design patterns (a different dimension from skill-authoring patterns). Want me to run it?
```

If yes: invoke the prompt plugin against the SKILL.md (the enhanced version if Apply was selected, the original if Skip was selected).

If no: end the session.

**One question at a time.** Never combine the prompt plugin offer with the apply/skip choice or any other question.

## Error Handling

| Condition | Response |
|-----------|----------|
| No path and no SKILL.md in conversation | Error message from Step 1. Stop. |
| File not found | Error message from Step 1. Stop. |
| File is empty | Error message from Step 1. Stop. |
| No frontmatter or missing name/description | Error message from Step 1. Stop. |
| Knowledge file unavailable | Error message from Step 2. Stop. |
| Already optimal (all applicable patterns strong) | Return unchanged with strength list (Step 4). No changelog. |
| File creation blocked (permissions or disk) | Present enhanced content inline instead of writing files. Note which files could not be written. |
| Enhanced score not improved | Revisit the rewrite (Step 9a). If genuinely no improvement is possible, treat as already-optimal (Step 4). |
