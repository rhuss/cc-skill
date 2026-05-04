---
name: "skill:check"
description: "Evaluate a SKILL.md file against 14 skill-authoring patterns. Use when reviewing skill quality, checking pattern coverage, testing activation metadata, or assessing a skill before sharing. Do NOT use for prompt-level analysis (use prompt:skill-checker instead) or for enhancing/rewriting skills (use skill:enhance instead)."
argument-hint: "[path/to/SKILL.md]"
user-invocable: true
---

# Skill Authoring Check

Evaluate a Claude Code SKILL.md file against 14 skill-authoring patterns organized across 5 categories: Discovery, Context Economy, Instruction Calibration, Workflow Control, and Executable Code, plus a Meta category. The output is a pattern checklist with two-tier quality ratings (strong vs. present), an activation test, and an optional prompt-pattern analysis when the prompt plugin is available.

This is a read-only analysis skill. It inspects the skill file and its parent directory but does not modify any files.

## Procedure

### Step 1: Obtain the SKILL.md File

Determine the target SKILL.md file from one of these sources, checked in order:

1. **Argument path**: The user provides a path after the command (e.g., `/skill:check path/to/SKILL.md`).
2. **Conversation context**: If no argument was given, look for the most recently referenced SKILL.md file in the conversation. This includes files the user mentioned, opened, or created earlier in the session.

Once you have a candidate path:

- Read the file using the Read tool.
- Confirm the file contains YAML frontmatter (delimited by `---` lines at the top).
- Confirm the frontmatter includes both a `name` and a `description` field.

If validation fails, return the appropriate error from the Error Handling section and stop.

Store the validated path as `SKILL_PATH` and the file content as `SKILL_CONTENT` for the remaining steps.

### Step 2: Load Pattern Knowledge

Read the pattern reference file using the Read tool:

```
${CLAUDE_PLUGIN_ROOT}/knowledge/skill-authoring-patterns.md
```

This file defines all 14 patterns with their detection signals, quality criteria, applicability conditions, and improvement guidance. You need these definitions to perform the evaluation in Step 3.

If the file cannot be loaded, return this error and stop:

```
**Error**: Could not load skill-authoring patterns from `${CLAUDE_PLUGIN_ROOT}/knowledge/skill-authoring-patterns.md`. The checker cannot run without pattern definitions.
```

### Step 3: Evaluate Patterns

Evaluate `SKILL_CONTENT` against each of the 14 patterns from the knowledge file. For each pattern, follow this procedure:

1. **Check applicability**. Some patterns are conditional (they apply only when certain conditions are met). Read the pattern's applicability and condition fields from the knowledge file. If the condition does not apply to this skill, mark the pattern as **N/A** and move on.

   When a pattern's condition is borderline (e.g., the skill is close to 200 lines, or "non-obvious" is debatable), lean toward marking it applicable. Rating a borderline pattern as N/A hides a potential improvement; rating it as "present" or "absent" surfaces it for review.

2. **Inspect the skill directory**. In addition to reading `SKILL_CONTENT`, use the Glob and Read tools to examine the parent directory of `SKILL_PATH`. Look for:
   - A `scripts/` subdirectory with helper scripts
   - Companion `.md` files referenced by the skill
   - Other sibling files that the skill mentions or depends on

   This directory inspection is needed because some patterns (Utility Bundle, Progressive Disclosure) depend on files outside the SKILL.md itself.

3. **Apply detection signals**. For each applicable pattern, check the detection signals listed in the knowledge file against `SKILL_CONTENT` and the directory contents. Note which signals are present and which are absent.

4. **Classify quality**. Based on the quality criteria in the knowledge file, assign one of these statuses:
   - **strong**: Meets the "Strong" quality criteria. The pattern is applied effectively and would hold up in edge cases.
   - **present**: Meets the "Present" quality criteria. The pattern exists but has gaps, is vague, or could be improved.
   - **absent**: None of the detection signals are found. The pattern is missing entirely.
   - **N/A**: The pattern's condition does not apply to this skill (conditional patterns only).

   The "present" vs. "strong" distinction is the most consequential judgment call in this step. A pattern is "present" when the skill does the thing but a reader could still misapply it in an edge case. A pattern is "strong" when the instructions are specific enough that an edge case would be handled correctly without further clarification.

   **Borderline example**: A skill's error handling section lists "File not found" and "Empty file" conditions but omits "file exists but is not valid YAML." Is the Known Gotchas pattern "present" or "strong"? It is "present" because the coverage exists but a practitioner would still miss a common failure mode. To reach "strong," the gotcha coverage must include the non-obvious cases, not just the ones a careful reader would already anticipate.

5. **Write a note**. Write one sentence explaining the classification. Reference specific content from the skill (a section name, a phrase, a missing element) so the note is actionable. Do not use generic observations.

   Notes must be specific enough that a reader can understand the rating without re-reading the skill. This is because the note is the primary feedback mechanism: vague notes waste the user's time and make the checklist decorative rather than diagnostic.

   For example, a strong Activation Metadata note might read: "Description names 4 trigger verbs and 2 exclusion targets with `argument-hint` present." A weak note would read: "Frontmatter looks good."

   Common mistake: writing notes that describe the pattern definition instead of the skill's application of it. "Execution Checklist means steps are numbered" describes the pattern. "Six numbered steps with halt conditions at Steps 1 and 2" describes the skill. Always write the second kind.

Record all 14 evaluations for use in Step 6.

### Step 4: Test Activation

Analyze the `description` field from the skill's frontmatter to evaluate how well it guides Claude's routing decisions.

1. **Generate trigger scenarios**. Based on the description text, write at least 3 example user requests that should activate this skill. These should be realistic phrasings a user would type, not contrived examples. Vary the wording to test different trigger paths.

2. **Generate non-trigger scenarios**. Write at least 1 example user request that sounds related but should NOT activate this skill. If the description includes exclusion clauses, derive the non-trigger from those. Non-triggers test whether the description's boundaries are specific enough to prevent misrouting.

3. **Assess description quality**. Write 1-3 observations about the description's effectiveness as a routing rule. Consider:
   - Does it name specific actions that map to user intent?
   - Does it include exclusion phrases that prevent false activation?
   - Would Claude be able to distinguish this skill from similar ones based on the description alone?
   - Is the `argument-hint` present and clear (if the skill accepts input)?

### Step 5: Check for Prompt Plugin

Determine whether the prompt plugin's skills are available in the current session. Check for any available skill with a `prompt:` prefix that evaluates SKILL.md files (e.g., `prompt:skill-checker`). The prompt plugin skill name may vary across installations, so match by prefix and purpose rather than exact name.

**If available**: Invoke the prompt plugin's skill checker against the same `SKILL_PATH`. Capture the output to include as a "Prompt Pattern Analysis" section in the final report.

**If unavailable**: Skip this step entirely. Do not mention the prompt plugin, do not warn about its absence, and do not add a placeholder section. The skill operates standalone by default, and the prompt analysis is purely additive when the plugin happens to be loaded.

### Step 6: Produce Output

Format the complete assessment using the structure below. Fill in values from the evaluations performed in Steps 3 and 4.

Here is a partial filled example showing how a completed assessment reads for two patterns:

```
| # | Pattern | Category | Status | Notes |
|---|---------|----------|--------|-------|
| 1 | Activation Metadata | Discovery | strong | Description names 4 trigger verbs and 2 exclusion targets with `argument-hint` present. |
| 2 | Exclusion Clause | Discovery | present | Generic "not for general use" without naming the adjacent skill to route to instead. |
```

Full output template:

```
## Skill Authoring Assessment

**File**: `<SKILL_PATH>`

### Pattern Checklist

| # | Pattern | Category | Status | Notes |
|---|---------|----------|--------|-------|
| 1 | Activation Metadata | Discovery | <status> | <one-line note> |
| 2 | Exclusion Clause | Discovery | <status> | <one-line note> |
| 3 | Context Budget | Context Economy | <status> | <one-line note> |
| 4 | Progressive Disclosure | Context Economy | <status> | <one-line note> |
| 5 | Control Tuning | Instruction Calibration | <status> | <one-line note> |
| 6 | Explain-the-Why | Instruction Calibration | <status> | <one-line note> |
| 7 | Template Scaffold | Instruction Calibration | <status> | <one-line note> |
| 8 | In-Skill Examples | Instruction Calibration | <status> | <one-line note> |
| 9 | Known Gotchas | Instruction Calibration | <status> | <one-line note> |
| 10 | Execution Checklist | Workflow Control | <status> | <one-line note> |
| 11 | Self-Correcting Loop | Workflow Control | <status> | <one-line note> |
| 12 | Plan-Validate-Execute | Workflow Control | <status> | <one-line note> |
| 13 | Utility Bundle | Executable Code | <status> | <one-line note> |
| 14 | Autonomy Calibration | Meta | <status> | <one-line note> |

**Summary**: <A> of <B> applicable patterns present, <C> of <B> strong, <D> improvements suggested
```

The trigger/non-trigger scenarios and description observations follow the pattern checklist. Truncate the description excerpt to 100 characters with `...` appended, so the activation test stays scannable without reproducing the full description.

```
### Activation Test

**Description analyzed**: "<first 100 characters of description>..."

**Would trigger on**:
- "<example user request 1>"
- "<example user request 2>"
- "<example user request 3>"

**Should NOT trigger on**:
- "<example non-matching request>"

**Observations**: <notes on description quality>
```

**Counting rules for the summary line**:

- **B** = number of applicable patterns (total 14 minus any marked N/A)
- **A** = number of patterns with status "strong" or "present" (not absent, not N/A)
- **C** = number of patterns with status "strong" only
- **D** = number of patterns with status "present" or "absent" (these are candidates for improvement)

**If the prompt plugin was available** (Step 5 produced output), append a final section:

```
### Prompt Pattern Analysis

<output from /prompt:check>
```

**Formatting rules**:

- Status values in the table must be one of: `strong`, `present`, `absent`, `N/A`
- Each note is a single sentence, not a paragraph
- The summary line uses the exact format shown, with counts filled in
- Trigger and non-trigger examples are quoted strings
- Do not include the full skill content in the output
- Produce the complete output in a single response (no follow-up messages, no interactive prompts)

## Error Handling

| Condition | Response |
|-----------|----------|
| No argument provided and no SKILL.md referenced in conversation | Return: "**Error**: No SKILL.md file specified. Provide a path as an argument (e.g., `/skill:check path/to/SKILL.md`) or reference a SKILL.md file in the conversation first." |
| File not found (path does not exist) | Return: "**Error**: File not found: `<path>`. Please provide a valid path to a SKILL.md file." |
| File is empty (0 bytes) | Return: "**Error**: The file at `<path>` is empty. A SKILL.md file needs YAML frontmatter with `name` and `description` fields at minimum." |
| File has no YAML frontmatter or missing required fields | Return: "**Error**: `<path>` does not appear to be a valid SKILL.md file. Expected YAML frontmatter with `name` and `description` fields." |
| File exists but contains binary or non-text content | Return: "**Error**: `<path>` does not appear to be a text file. SKILL.md files must be plain text with YAML frontmatter." |
| YAML frontmatter delimiters present but content between them is not valid YAML | Return: "**Error**: `<path>` has frontmatter delimiters but the content between them is not valid YAML. Check for syntax errors (missing colons, bad indentation, unquoted special characters)." |
| Knowledge file unavailable | Return: "**Error**: Could not load skill-authoring patterns from `${CLAUDE_PLUGIN_ROOT}/knowledge/skill-authoring-patterns.md`. The checker cannot run without pattern definitions." |
