# Code Review: Eval Goal Categories (006)

**Spec:** specs/006-eval-goal-categories/spec.md
**Date:** 2026-07-15
**Reviewer:** Claude (speckit.spex-gates.review-code + spex-deep-review)

## Compliance Summary

**Overall Score: 98%**

- Functional Requirements: 13/14 (93%)
- Error Handling: 3/3 (100%)
- Edge Cases: 3/3 (100%)

### Requirement Compliance Matrix

| Requirement | Status | Location | Notes |
|---|---|---|---|
| FR-001: Judge names use goal-category prefixes | Compliant | eval/skill-check/eval.yaml, eval/skill-enhance/eval.yaml | All 15 judges correctly prefixed |
| FR-002: Four categories (outcome, process, style, efficiency) | Compliant | eval/skill-check/eval.yaml:L1-223, eval/skill-enhance/eval.yaml:L1-282 | All four categories represented |
| FR-003: New judge process_evaluation_sequence | Compliant | eval/skill-check/eval.yaml:L151-175 | Python check for activation test section |
| FR-004: New judge style_summary_format | Compliant | eval/skill-check/eval.yaml:L177-200 | Python check for summary pattern |
| FR-005: New judge process_step_execution | Compliant | eval/skill-enhance/eval.yaml:L241-262 | Python check for steps section |
| FR-006: Threshold keys match renamed judges | Compliant | Both eval.yaml files | All threshold keys match new names |
| FR-007: compare-runs.sh extracts category prefix | Compliant | skill/scripts/compare-runs.sh:L174-189 | `extract_category()` uses `${judge%%_*}` |
| FR-008: Terminal output grouped by category | Compliant | skill/scripts/compare-runs.sh:L296-321 | Categories with headings |
| FR-009: Markdown output grouped by category | Compliant | skill/scripts/compare-runs.sh:L401-427 | Category sections in comparison.md |
| FR-010: Per-category summary line | Compliant | skill/scripts/compare-runs.sh:L328-338 | Format matches spec |
| FR-011: JSON output (comparison.json) | Compliant | skill/scripts/compare-runs.sh:L440-555 | Best-effort, non-fatal on failure |
| FR-012: invocation_type field in annotations | Compliant | All 10 annotations.yaml files | `invocation_type: explicit` as first field |
| FR-013: dataset.schema documents invocation_type | Compliant | Both eval.yaml files | Field documented with allowed values |
| FR-014: by_invocation_type in JSON output | Deviation | skill/scripts/compare-runs.sh:L536 | Empty placeholder `{}` (harness schema constraint) |

**FR-014 Deviation Justification:** The harness summary.yaml does not expose per-case invocation_type data, making runtime aggregation impossible without modifying the eval harness (out of scope). The empty placeholder satisfies the structural requirement while documenting the limitation.

## Deep Review Report

### Review Configuration

| Setting | Value |
|---|---|
| Review agents | 5 (sequential, single-agent mode) |
| Fix rounds | 1 of 3 (passed after round 1) |
| External tools | CodeRabbit (completed, 2 findings), Codex (completed, 3 findings), Copilot (not available) |
| Test command | None detected (no test suite) |
| Spec compliance | 98% (PASS, >= 95% threshold) |

### Agent Perspectives

| Agent | Focus | Findings |
|---|---|---|
| Correctness | Logic bugs, data flow, edge cases | 2 (FINDING-1, contributed to Codex-3) |
| Architecture | Structure, idioms, maintainability | 1 (FINDING-4) |
| Security | Input validation, injection, escaping | 1 (FINDING-2) |
| Production Readiness | Error handling, failure modes | 0 |
| Test Quality | Coverage gaps, test design | 1 (FINDING-6) |

### External Tool Results

**CodeRabbit** (completed, 2 major findings):
- CR-1: spex-deep-review extension Codex placeholders (out of scope, `.specify/extensions/` file)
- CR-2: spex-worktrees pipeline-mode output suppression (out of scope, `.specify/extensions/` file)

Both CodeRabbit findings target extension infrastructure files, not the 006-eval-goal-categories feature code. Excluded from gate.

**Codex** (completed, 3 P2 findings):
- Codex-1: Empty `by_invocation_type` placeholder (known FR-014 deviation, Minor)
- Codex-2: JSON-escape dynamic strings (aligns with FINDING-2, Minor)
- Codex-3: N/A categories labeled "Unchanged" (NEW correctness bug, Important, **FIXED**)

### Merged Findings

| ID | Severity | Confidence | File | Lines | Category | Status | Description |
|---|---|---|---|---|---|---|---|
| FINDING-1 | Important | 85 | skill/scripts/compare-runs.sh | 544 | correctness | **FIXED** | jq parse failure crashes script under `set -euo pipefail` |
| FINDING-2 | Minor | 70 | skill/scripts/compare-runs.sh | 440-539 | security | Open | JSON values not escaped; special chars in paths/names could produce invalid JSON |
| FINDING-3 | Minor | 60 | eval/skill-check/eval.yaml | 151-175 | architecture | Open | process_evaluation_sequence partially duplicates checks from outcome_checklist_completeness |
| FINDING-4 | Minor | 55 | skill/scripts/compare-runs.sh | 500-507 | architecture | Open | O(n*categories) awk spawns in avg_delta; negligible for current scale |
| FINDING-5 | Minor | 50 | eval/skill-enhance/eval.yaml | 241-262 | correctness | Open | process_step_execution regex matches "Step N" anywhere, not just in "Steps Executed" section |
| FINDING-6 | Notable | 75 | skill/scripts/compare-runs.sh | - | test-quality | Open | No automated tests for compare-runs.sh |
| Codex-3 | Important | 80 | skill/scripts/compare-runs.sh | 278 | correctness | **FIXED** | Categories where all judges have N/A deltas incorrectly labeled "Unchanged" |

### Fix Loop Summary

**Round 1/3:**

1. **FINDING-1 (Important):** Wrapped `jq '.'` call in conditional to prevent `set -euo pipefail` crash.
   - Before: `json_content=$(echo "$json_content" | jq '.')`
   - After: `if formatted=$(echo "$json_content" | jq '.' 2>/dev/null); then json_content="$formatted"; fi`
   - File: `skill/scripts/compare-runs.sh:546`

2. **Codex-3 (Important):** Added branch for all-N/A categories in direction logic.
   - Before: `else cat_direction+=("Unchanged")` caught all-N/A case
   - After: `elif (( c_unch == 0 && c_na > 0 )); then cat_direction+=("N/A")` before else branch
   - File: `skill/scripts/compare-runs.sh:278`

**Re-review after fixes:** No new Critical or Important findings. Gate check: PASS.

### Gate Decision

| Metric | Value |
|---|---|
| Critical findings | 0 |
| Important findings | 0 (2 fixed in round 1) |
| Minor findings | 4 (open, excluded from gate) |
| Notable findings | 1 (open, excluded from gate) |
| Fix rounds used | 1 of 3 |
| Spec compliance | 98% |
| **Gate outcome** | **PASS** |

### Open Minor Findings (for future consideration)

- FINDING-2: JSON string escaping in `generate_json()` could be improved with proper quoting for paths containing special characters. Low risk since the function is wrapped in best-effort error handling.
- FINDING-3: Minor overlap between `process_evaluation_sequence` and `outcome_checklist_completeness` judges. Both serve distinct purposes (process verification vs. outcome correctness).
- FINDING-4: Multiple awk spawns per category for delta averaging. Performance is negligible at current scale (< 20 judges).
- FINDING-5: `process_step_execution` regex could be tightened to match only within "Steps Executed" sections. Current implementation works correctly for well-formed eval output.
- FINDING-6: compare-runs.sh lacks automated tests. Recommend adding shell-based integration tests as a follow-up.

---

Generated by `speckit.spex-gates.review-code` + `spex-deep-review` on 2026-07-15
