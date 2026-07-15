---
name: "skill:check"
description: "Evaluate a SKILL.md file using three-layer linting: schema validation, 17 skill-authoring patterns, and optional substance review (--deep). Use when reviewing skill quality, checking pattern coverage, testing activation metadata, or assessing a skill before sharing. Add --deep for qualitative substance review. Do NOT use for prompt-level analysis (use prompt:skill-checker instead) or for enhancing/rewriting skills (use skill:enhance instead)."
argument-hint: "[path/to/SKILL.md] [--deep]"
user-invocable: true
---

# Skill Authoring Check

Evaluate a Claude Code SKILL.md file using a three-layer linting model:

- **Layer 1 (Schema Validation)**: Deterministic pass/fail checks for frontmatter structure, field validity, description length, body size, and token budget.
- **Layer 2 (Pattern & Principle Assessment)**: Evaluate 17 skill-authoring patterns organized across 7 categories (Discovery, Context Economy, Instruction Calibration, Workflow Control, Executable Code, Workflow Quality, Meta). Three-state quality ratings (strong, present, absent) with principle-level enrichments.
- **Layer 3 (Substance Review)**: Optional deep qualitative review enabled with `--deep`. Assesses purpose sensibility, harmful output risk, example realism, and workflow completeness.

The output includes all active layers, an activation test, and an optional prompt-pattern analysis when the prompt plugin is available.

This is a read-only analysis skill. It inspects the skill file and its parent directory but does not modify any files.

## Procedure

### Step 1: Obtain the SKILL.md File

Determine the target SKILL.md file and optional flags from the argument string:

1. **Parse arguments**: The argument string may contain a file path and optional flags. Extract:
   - **File path**: The path to the SKILL.md file (e.g., `path/to/SKILL.md`)
   - **`--deep` flag**: If present, enables Layer 3 Substance Review. Store as `DEEP_MODE = true/false`.
   
   Examples: `/skill:check path/to/SKILL.md --deep`, `/skill:check --deep path/to/SKILL.md`, `/skill:check path/to/SKILL.md`

2. **Resolve file path** from one of these sources, checked in order:
   - **Argument path**: The user provides a path in the argument string (e.g., `/skill:check path/to/SKILL.md`).
   - **Conversation context**: If no path was found in the arguments, look for the most recently referenced SKILL.md file in the conversation. This includes files the user mentioned, opened, or created earlier in the session.

Once you have a candidate path:

- Read the file using the Read tool.
- If the file contains binary or non-text content (the Read tool returns an error or the content contains null bytes or is not valid UTF-8), return the binary content error from the Error Handling table and stop.

Store the path as `SKILL_PATH` and the file content as `SKILL_CONTENT` for the remaining steps. Do NOT validate frontmatter here; frontmatter presence and validity are checked by Layer 1 (Step 2.5, check 1).

### Step 2: Load Pattern Knowledge

Read the pattern reference file using the Read tool:

```text
${CLAUDE_PLUGIN_ROOT}/knowledge/skill-authoring-patterns.md
```

This file defines all 17 patterns with their detection signals, quality criteria, applicability conditions, and improvement guidance. You need these definitions to perform the evaluation in Step 3.

If the file cannot be loaded, return this error and stop:

```text
**Error**: Could not load skill-authoring patterns from `${CLAUDE_PLUGIN_ROOT}/knowledge/skill-authoring-patterns.md`. The checker cannot run without pattern definitions.
```

### Step 2.5: Layer 1 Schema Validation

Before pattern evaluation, run deterministic structural checks against `SKILL_CONTENT`. These checks have binary pass/fail/warn outcomes and require no LLM judgment beyond reading the content.

Run each check in order and record the result:

1. **Frontmatter presence**: Check that YAML frontmatter exists (content between `---` delimiters at the top of the file). Result: PASS if present and parseable as valid YAML, FAIL if missing or malformed. Remediation: "Add `---` delimiters with `name` and `description` fields at the top of the file."

2. **Required fields**: Check that `name` and `description` fields exist in the frontmatter and have non-empty string values. A field that is present but null, empty, or non-string (e.g., a number or list) counts as missing. Result: FAIL for each missing or invalid field. Remediation: "Add a non-empty string value for the `<field>` field in the YAML frontmatter."

3. **Description character count**: Count the characters in the `description` field value. Skip this check if the description field failed check 2 (missing or invalid). Result: WARN if over 1024 characters (Agent Skills spec limit for the `description` field alone). If the frontmatter also contains a `when-to-use` or `when_to_use` field (accept either spelling), count the combined character length of `description` + that field and WARN if over 1536 characters (Claude Code combined limit). Include the actual character count in the result. Remediation: "Description is <N> characters. Agent Skills spec limit is 1024. [If when-to-use/when_to_use present: Combined is <M> characters; Claude Code limit is 1536.] Shorten the description to focus on routing triggers."

4. **Known field validation**: Check all frontmatter field names against the known set: `name`, `description`, `argument-hint`, `arguments`, `user-invocable`, `disable-model-invocation`, `allowed-tools`, `when-to-use`, `when_to_use`, `model`, `hooks`. Both `when-to-use` and `when_to_use` are accepted (platforms use different conventions). Result: WARN for each unknown field. Remediation: "Unknown frontmatter field `<field>`. Known fields are: name, description, argument-hint, arguments, user-invocable, disable-model-invocation, allowed-tools, when-to-use/when_to_use, model, hooks."

5. **Body line count**: Count the lines in the body (everything after the closing `---` of the frontmatter). Result: WARN if over 500 lines. Include the actual line count. Remediation: "Body is <N> lines. Consider splitting into a main SKILL.md and companion reference files (see Progressive Disclosure pattern)."

6. **Token budget estimate**: Estimate the token count of the body using word count multiplied by 1.3. Result: WARN if the estimate exceeds 5000 tokens. Include the estimate. Remediation: "Estimated <N> tokens (based on <W> words). Consider reducing body size or moving reference material to companion files."

Store the results as `LAYER1_RESULTS` (list of check name, result, and remediation hint for failures/warnings). Count PASS, WARN, and FAIL results for the summary line.

### Step 3: Evaluate Patterns

Evaluate `SKILL_CONTENT` against each of the 17 patterns from the knowledge file. For each pattern, follow this procedure:

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

Record all 17 evaluations for use in Step 6.

### Step 3.5: Lifecycle Signal Check

After pattern evaluation, check `SKILL_CONTENT` and its frontmatter for lifecycle metadata. This is an informational check, not a quality rating. The checker cannot observe runtime behavior, so these checks only note metadata presence.

Check for:
1. **Last-tested date**: Look for a `last-tested`, `last_tested`, or similar date field in the frontmatter or body. Note if present (with the date value) or absent.
2. **Owner**: Look for an `owner`, `author`, or `maintainer` field in the frontmatter or body. Note if present (with the value) or absent.
3. **Version**: Look for a `version` field in the frontmatter or body. Note if present (with the value) or absent.

Store these as `LIFECYCLE_SIGNALS` for the output. If lifecycle fields are present but values appear stale (e.g., a last-tested date more than 6 months old), note the staleness as an observation, not a failure.

### Step 4: Test Activation

**Skip this step if** the `description` field is missing or invalid (Layer 1 check 2 reported FAIL for description). When skipped, output "Activation Test: skipped (no valid description)" in place of the activation test section.

Analyze the `description` field from the skill's frontmatter to evaluate how well it guides Claude's routing decisions.

1. **Generate trigger scenarios**. Based on the description text, write at least 3 example user requests that should activate this skill. These should be realistic phrasings a user would type, not contrived examples. Vary the wording to test different trigger paths.

2. **Generate non-trigger scenarios**. Write at least 1 example user request that sounds related but should NOT activate this skill. If the description includes exclusion clauses, derive the non-trigger from those. Non-triggers test whether the description's boundaries are specific enough to prevent misrouting.

3. **Assess description quality**. Write 1-3 observations about the description's effectiveness as a routing rule. Consider:
   - Does it name specific actions that map to user intent?
   - Does it include exclusion phrases that prevent false activation?
   - Would Claude be able to distinguish this skill from similar ones based on the description alone?
   - Is the `argument-hint` present and clear (if the skill accepts input)?

### Step 5: Layer 3 Substance Review (--deep only)

**Skip this step entirely if `DEEP_MODE` is false.** When `--deep` was not specified, proceed directly to Step 6.

When `DEEP_MODE` is true, perform a qualitative substance review of the skill. This review answers senior-engineer questions that structural and pattern checks cannot address. Assess the skill content and produce a narrative with labeled subsections:

1. **Purpose Sensibility**: Does the skill do something sensible for its stated purpose? Is the described task real and useful, or contrived? Would a team actually use this skill in their workflow?

2. **Harmful Output Risk**: Could the instructions produce harmful, misleading, or destructive output if followed literally? Are there steps that could damage files, expose secrets, or produce unsafe code without safeguards?

3. **Example Realism**: Are the examples (if any) realistic and representative of actual use? Do they match the skill's stated purpose, or are they contrived to demonstrate features without reflecting real usage?

4. **Workflow Completeness**: Does the workflow have dead ends, unreachable branches, or missing error paths? Can every decision point reach a valid outcome? Are there steps that assume prior state without verifying it?

After the four subsections, write an **Overall Verdict** line with a one-sentence summary and a rating:
- **pass**: The skill is substantively sound. No significant concerns.
- **concern**: The skill works but has qualitative issues that warrant attention (unrealistic examples, incomplete error paths, vague purpose).
- **fail**: The skill has substantive problems (harmful output risk, fundamentally broken workflow, nonsensical purpose).

Format the Layer 3 output as:

```text
## Layer 3: Substance Review

**Purpose Sensibility**: <1-3 sentences>

**Harmful Output Risk**: <1-3 sentences>

**Example Realism**: <1-3 sentences>

**Workflow Completeness**: <1-3 sentences>

**Overall Verdict**: <one-sentence summary> — <pass/concern/fail>
```

Store the verdict rating for use in the summary line.

### Step 6: Check for Prompt Plugin

Determine whether the prompt plugin's skills are available in the current session. Check for any available skill with a `prompt:` prefix that evaluates SKILL.md files (e.g., `prompt:skill-checker`). The prompt plugin skill name may vary across installations, so match by prefix and purpose rather than exact name.

**If available**: Invoke the prompt plugin's skill checker against the same `SKILL_PATH`. Capture the output to include as a "Prompt Pattern Analysis" section in the final report.

**If unavailable**: Skip this step entirely. Do not mention the prompt plugin, do not warn about its absence, and do not add a placeholder section. The skill operates standalone by default, and the prompt analysis is purely additive when the plugin happens to be loaded.

### Step 7: Produce Output

Format the complete assessment using the structure below. Fill in values from the evaluations performed in Steps 2.5, 3, 3.5, 4, and 5.

The output has three clearly separated sections. Layer 3 only appears when `DEEP_MODE` is true.

Full output template:

```text
## Skill Authoring Assessment

**File**: `<SKILL_PATH>`

## Layer 1: Schema Validation

| Check | Result | Details |
|-------|--------|---------|
| Frontmatter presence | <PASS/FAIL> | <details or remediation hint> |
| Required field: name | <PASS/FAIL> | <details or remediation hint> |
| Required field: description | <PASS/FAIL> | <details or remediation hint> |
| Description character count | <PASS/WARN> | <character count and limit comparison> |
| Known field validation | <PASS/WARN> | <unknown fields listed, or "all fields recognized"> |
| Body line count | <PASS/WARN> | <line count and threshold comparison> |
| Token budget estimate | <PASS/WARN> | <estimated tokens and threshold comparison> |

## Layer 2: Pattern & Principle Assessment

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
| 15 | Process over Prose | Workflow Quality | <status> | <one-line note> |
| 16 | Anticipate the Excuse | Workflow Quality | <status> | <one-line note> |
| 17 | Stay in Scope | Workflow Quality | <status> | <one-line note> |

#### Lifecycle Signals

_Limited observability: the checker cannot verify runtime behavior, test execution, or ownership activity. These checks note metadata presence only._

- **Last-tested date**: <present with date / absent>
- **Owner**: <present with value / absent>
- **Version**: <present with value / absent>

**Summary**: Layer 1: <X>/<Y> passed | <A> of <B> patterns present, <C> strong
```

If `DEEP_MODE` is true, append ` | Deep: <verdict>` to the summary line:

```text
**Summary**: Layer 1: <X>/<Y> passed | <A> of <B> patterns present, <C> strong | Deep: <verdict>
```

If `DEEP_MODE` is true, append the Layer 3 section after the summary line (inside the output, before the Activation Test):

```text
## Layer 3: Substance Review

**Purpose Sensibility**: <1-3 sentences>

**Harmful Output Risk**: <1-3 sentences>

**Example Realism**: <1-3 sentences>

**Workflow Completeness**: <1-3 sentences>

**Overall Verdict**: <one-sentence summary> — <pass/concern/fail>
```

The `[Deep: <verdict>]` segment in the summary line only appears when `DEEP_MODE` is true.

**Counting rules for Layer 1 summary**:
- `<Y>` is the total number of Layer 1 result rows displayed (typically 7: frontmatter presence, name, description, description character count, known fields, body line count, token budget). May be fewer if checks were skipped (e.g., description character count skipped when description field is missing)
- `<X>` is the number of checks with PASS result only. WARN and FAIL results are NOT counted as passed. A check that produced WARN counts toward Y (denominator) but not X (numerator), making WARNs visible in the ratio.

The trigger/non-trigger scenarios and description observations follow the pattern checklist. Truncate the description excerpt to 100 characters with `...` appended, so the activation test stays scannable without reproducing the full description.

```text
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

- **X** = number of Layer 1 checks with PASS result (not WARN, not FAIL)
- **Y** = total number of Layer 1 checks run
- **B** = number of applicable patterns (total 17 minus any marked N/A)
- **A** = number of patterns with status "strong" or "present" (not absent, not N/A)
- **C** = number of patterns with status "strong" only

**If the prompt plugin was available** (Step 6 produced output), append a final section:

```text
### Prompt Pattern Analysis

<output from the prompt plugin skill>
```

**Formatting rules**:

- Layer 1 result values must be one of: `PASS`, `WARN`, `FAIL`
- Status values in the pattern table must be one of: `strong`, `present`, `absent`, `N/A`
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
| File exists but contains binary or non-text content | Return: "**Error**: `<path>` does not appear to be a text file. SKILL.md files must be plain text with YAML frontmatter." |
| Knowledge file unavailable | Return: "**Error**: Could not load skill-authoring patterns from `${CLAUDE_PLUGIN_ROOT}/knowledge/skill-authoring-patterns.md`. The checker cannot run without pattern definitions." |
