# Deep Review Findings

**Date:** 2026-05-28
**Branch:** 003-eval-automation
**Rounds:** 2 (round 1 from quality gate, round 2 manual)
**Gate Outcome:** PASS
**Invocation:** manual

## Summary

| Severity | Found | Fixed | Remaining |
|----------|-------|-------|-----------|
| Critical | 1 | 1 | 0 |
| Important | 2 | 2 | 0 |
| Minor | 13 | 4 | 9 |
| **Total** | **16** | **7** | **9** |

**Agents completed:** 5/5 (+ 0 external tools)
**CodeRabbit:** skipped (no committed files to review)
**Copilot:** not installed

## Round 1 Fixes (from quality gate)

### FINDING-1 (Critical, fixed round 1)
- **File:** skill/scripts/compare-runs.sh:115,126,142
- **Category:** correctness, security, production-readiness
- **Source:** production-agent (also: correctness, security, architecture)

**What is wrong:** AWK injection via unsanitized variable interpolation. Shell variables were embedded directly into double-quoted awk program strings.

**How it was resolved:** All awk calls now use `-v` flag. Added `is_numeric()` validation. Extracted shared `classify_delta()` function. Added `*)` fallback cases.

### FINDING-2 (Important, fixed round 1)
- **File:** skill/scripts/compare-runs.sh:59-62
- **Category:** production-readiness
- **Source:** production-agent (also: correctness, test)

**What is wrong:** Silent yq parse failures produced misleading "no judges" error.

**How it was resolved:** Replaced `|| true` with explicit yq exit status checking and specific error messages.

### FINDING-3 (Important, fixed round 1)
- **File:** skill/scripts/compare-runs.sh:103
- **Category:** correctness
- **Source:** correctness-agent

**What is wrong:** `format_score` silently converted non-numeric values to `0.000`.

**How it was resolved:** Added `is_numeric()` guard in both `format_score()` and `get_score()`.

## Round 2 Fixes (Minor, applied proactively)

### FINDING-4 (Minor, fixed round 2)
- **File:** skill/scripts/compare-runs.sh:103-105
- **Category:** correctness
- **Source:** correctness-agent

**What is wrong:** `is_numeric` regex rejected scientific notation (e.g., `1.5e-3`).

**How it was resolved:** Extended regex to `^-?[0-9]*\.?[0-9]+([eE][+-]?[0-9]+)?$`.

### FINDING-5 (Minor, fixed round 2)
- **File:** skill/skills/measure/SKILL.md:172
- **Category:** architecture
- **Source:** architecture-agent

**What is wrong:** Error message referenced internal project name "cc-skill" instead of registered plugin name "skill".

**How it was resolved:** Changed to "Verify the plugin installation."

### FINDING-6 (Minor, fixed round 2)
- **File:** skill/scripts/compare-runs.sh:236-237
- **Category:** production-readiness
- **Source:** production-agent

**What is wrong:** `run_id` extraction lacked error handling, could abort script after terminal output but before report file.

**How it was resolved:** Added `2>/dev/null` and `|| fallback` pattern.

### FINDING-7 (Minor, fixed round 2)
- **File:** skill/.claude-plugin/plugin.json:3
- **Category:** architecture
- **Source:** architecture-agent

**What is wrong:** Version remained 1.0.0 after adding a new skill.

**How it was resolved:** Bumped to 1.1.0.

## Remaining Minor Findings

### FINDING-8 (Minor)
- **File:** skill/scripts/compare-runs.sh:80,87,94
- **Category:** security
- **Source:** security-agent (also: production-agent)

Judge names interpolated into yq expressions via shell expansion. Using yq's `--arg` flag would be safer but the current double-quoting handles typical judge names. Edge case only.

### FINDING-9 (Minor)
- **File:** skill/skills/measure/SKILL.md:24-36
- **Category:** architecture
- **Source:** architecture-agent

Step 1 (input handling) is duplicated across checker, enhancer, and measure skills. Could be extracted to a shared companion file.

### FINDING-10 (Minor)
- **File:** skill/CLAUDE.md
- **Category:** architecture
- **Source:** architecture-agent (round 1)

Plugin CLAUDE.md doesn't document the `scripts/` directory convention.

### FINDING-11 (Minor)
- **File:** skill/scripts/compare-runs.sh:241-288
- **Category:** production-readiness
- **Source:** production-agent

Report file write is not atomic. An interrupt could leave a partial file.

### FINDING-12 (Minor)
- **File:** skill/scripts/compare-runs.sh:239
- **Category:** production-readiness
- **Source:** production-agent (both rounds)

No writability check for enhanced directory before doing work.

### FINDING-13 (Minor)
- **File:** skill/scripts/compare-runs.sh:132-135
- **Category:** correctness
- **Source:** correctness-agent

`classify_delta` would misclassify non-numeric input (latent, not reachable through current callers).

### FINDING-14 (Minor)
- **File:** skill/scripts/compare-runs.sh:1-290
- **Category:** test-quality
- **Source:** test-agent

No automated tests. The spec chose manual testing, which is reasonable for initial delivery. A bats test suite would add regression safety.

### FINDING-15 (Minor)
- **File:** skill/scripts/compare-runs.sh:75-101
- **Category:** test-quality
- **Source:** test-agent

No contract test for the summary.yaml format dependency. A fixture-based test would catch format changes.

### FINDING-16 (Minor)
- **File:** skill/scripts/compare-runs.sh:75-101
- **Category:** production-readiness
- **Source:** production-agent (round 1)

O(N) yq process spawns per judge. Adequate for typical judge counts (<20).
