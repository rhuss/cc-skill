# Deep Review Findings

**Date:** 2026-05-31
**Branch:** 004-targeted-eval-dataset
**Rounds:** 1
**Gate Outcome:** PASS
**Invocation:** quality-gate

## Summary

| Severity | Found | Fixed | Remaining |
|----------|-------|-------|-----------|
| Critical | 1 | 1 | 0 |
| Important | 5 | 5 | 0 |
| Minor | 6 | 1 | 5 |
| **Total** | **12** | **7** | **5** |

**Agents completed:** 5/5 (+ 1 external tool)
**Agents failed:** none

## Findings

### FINDING-1
- **Severity:** Critical
- **Confidence:** 92
- **File:** skill/skills/measure/SKILL.md:63-66
- **Category:** correctness
- **Source:** correctness-agent
- **Round found:** 1
- **Resolution:** fixed (round 1)

**What is wrong:**
FR-004 violation: baseline eval (Step 3) ran before targeted cases were generated (Steps 4a-4d), so baseline used only the original dataset while the enhanced eval used the combined dataset. The spec requires both evals to use the same combined dataset.

**Why this matters:**
Comparing scores across different datasets invalidates the comparison. A score improvement could reflect the new cases being easier, not actual skill quality gain.

**How it was resolved:**
Added Step 4e (Re-run Baseline Against Combined Dataset) that restores the original SKILL.md, re-runs the baseline eval against the combined dataset, then restores the enhanced skill. Step 1 now saves `ORIGINAL_SKILL_CONTENT` for this purpose. Step 3 is documented as a "preliminary baseline" that gets replaced when targeted cases are generated.

### FINDING-2
- **Severity:** Important
- **Confidence:** 85
- **File:** skill/skills/measure/SKILL.md:165
- **Category:** correctness
- **Source:** correctness-agent (also reported by: coderabbit)
- **Round found:** 1
- **Resolution:** fixed (round 1)

**What is wrong:**
Step 4c's numbering logic said "find the highest existing NNN" once, but when generating multiple cases across multiple patterns, all cases would compute the same next number.

**Why this matters:**
Could produce duplicate directory names, causing overwrites or failures.

**How it was resolved:**
Changed to use a running counter `NEXT_CASE_NUM` initialized from the highest existing NNN, incremented after each successfully created case.

### FINDING-3
- **Severity:** Important
- **Confidence:** 80
- **File:** skill/skills/measure/SKILL.md:149-150
- **Category:** correctness
- **Source:** correctness-agent
- **Round found:** 1
- **Resolution:** fixed (round 1)

**What is wrong:**
Step 4b filtered `ENHANCEMENT_DIFF` into `UNCOVERED_PATTERNS` but only described storing pattern names, not `change_description`. Step 4c referenced `change_description` from entries in `UNCOVERED_PATTERNS`, which would be undefined.

**Why this matters:**
Without the change description, `/eval-dataset` invocations lack context about what specifically changed, reducing targeted case quality.

**How it was resolved:**
Step 4b now explicitly states that `UNCOVERED_PATTERNS` entries retain both `pattern_name` and `change_description` from the original `ENHANCEMENT_DIFF`.

### FINDING-4
- **Severity:** Important
- **Confidence:** 90
- **File:** skill/skills/measure/SKILL.md:12-18
- **Category:** architecture
- **Source:** architecture-agent
- **Round found:** 1
- **Resolution:** fixed (round 1)

**What is wrong:**
The workflow overview listed 5 sequential steps with no mention of sub-steps 4a-4f, creating ambiguity for an LLM following the overview.

**Why this matters:**
An LLM parsing only the overview would not anticipate the targeted case generation sub-workflow.

**How it was resolved:**
Updated the workflow overview to mention Steps 4a-4d (diff parsing and case generation) and Steps 4e-4f (re-baseline and review) explicitly.

### FINDING-5
- **Severity:** Important
- **Confidence:** 80
- **File:** skill/skills/measure/SKILL.md:162
- **Category:** production-readiness
- **Source:** production-agent
- **Round found:** 1
- **Resolution:** fixed (round 1)

**What is wrong:**
No upper bound on `targeted_cases_per_pattern`. A user could set it to 50, causing 50 x N expensive `/eval-dataset` invocations.

**Why this matters:**
Each invocation is a full LLM generation. Unbounded values could make the workflow impractically slow.

**How it was resolved:**
Added a hard cap: "Cap the value at 2 regardless of what is configured (to bound the cost of case generation)."

### FINDING-6
- **Severity:** Important
- **Confidence:** 80
- **File:** skill/skills/measure/SKILL.md:175
- **Category:** test-quality
- **Source:** test-agent
- **Round found:** 1
- **Resolution:** fixed (round 1)

**What is wrong:**
Step 4c verified case directory file existence but not content correctness. `annotations.yaml` could exist without a valid `targets_pattern` field.

**Why this matters:**
If `targets_pattern` is missing or misspelled, the coverage check in Step 4b (on future runs) would silently miss the case.

**How it was resolved:**
Added content validation: "Read `annotations.yaml` and confirm it contains a `targets_pattern` field matching the intended pattern name (case-insensitive). If validation fails, count the case as a failed pattern."

## Remaining Findings

### FINDING-7 (Minor)
- **File:** skill/skills/measure/SKILL.md:145-148
- **Category:** architecture
- **Source:** architecture-agent
- **Description:** No explicit clarification that cases without `annotations.yaml` or `targets_pattern` field are treated as non-covering (the slug-based match is a secondary heuristic).

### FINDING-8 (Minor)
- **File:** skill/skills/measure/SKILL.md:269-270
- **Category:** architecture
- **Source:** architecture-agent
- **Description:** No pre-existence check for `compare-runs.sh` before execution. The error table covers the failure, but a pre-check would be cleaner.

### FINDING-9 (Minor)
- **File:** skill/skills/measure/SKILL.md:241
- **Category:** security
- **Source:** security-agent
- **Description:** The "n" response deletes case directories without a secondary confirmation. Bounded to only `case-NNN-targeted-*` directories created in this session, so risk is low.

### FINDING-10 (Minor, partially addressed)
- **File:** skill/skills/measure/SKILL.md:167
- **Category:** security
- **Source:** security-agent
- **Description:** Pattern slug sanitization was underspecified. Now uses explicit `[a-z0-9-]` character set (fixed alongside FINDING-2).

### FINDING-11 (Minor)
- **File:** skill/skills/measure/SKILL.md:242
- **Category:** production-readiness
- **Source:** production-agent
- **Description:** The "edit" flow has no fallback for unrecognized responses beyond y/n/edit.

### FINDING-12 (Minor)
- **File:** skill/skills/measure/SKILL.md (error table)
- **Category:** test-quality
- **Source:** test-agent
- **Description:** No error handling entry for compare-runs.sh producing empty or malformed output.
