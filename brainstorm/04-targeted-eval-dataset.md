# Brainstorm: Targeted Eval Dataset for Enhancement Coverage

**Date:** 2026-05-28
**Status:** open

## Problem Framing

When `/skill:measure` runs the measure-enhance-measure loop, the eval dataset may not cover the areas that `/skill:enhance` improved. If the enhancer adds a Known Gotchas pattern but no test case exercises gotcha-handling behavior, the eval scores won't reflect that improvement. The comparison report shows no change even though the skill got meaningfully better.

This is a coverage gap between what the enhancer touches and what the eval dataset tests.

## Proposed Solution

After enhancing the skill, generate targeted test cases that cover the changed areas, merge them into the existing dataset, then run both baseline and enhanced evals against the combined dataset.

### Workflow

1. Enhance the skill (captures the diff of what changed)
2. Analyze the enhancement diff to identify which patterns were added or strengthened
3. Generate targeted test cases that exercise those specific patterns
4. Merge the targeted cases into `eval/cases/` alongside existing cases
5. Run the original (pre-enhancement) skill against the full dataset (baseline)
6. Run the enhanced skill against the full dataset (enhanced)
7. Compare with `compare-runs.sh`

### Why Merge Instead of Separate Datasets

The eval harness uses a single `dataset.path` per `eval.yaml`. It doesn't support multiple dataset directories. Merging is both the practical choice and the better long-term design: each enhance cycle accumulates broader coverage, so future runs benefit from a richer dataset without regenerating targeted cases.

The merge happens after generating the targeted cases but before running either eval. Both baseline and enhanced runs use the same combined dataset, keeping the comparison fair.

### Key Design Decision

Merge after generation, before comparison. The current comparison stays clean (same dataset for both runs). Future `/skill:measure` runs automatically benefit from the richer dataset.

## Approaches Considered

### A: Augment Dataset, Then Re-test Both

Enhance first, check dataset coverage against improvements, augment, re-run both evals.

- Pro: Single comparison covers regression and improvement
- Con: Need to re-run baseline with augmented dataset (extra eval pass)
- This is effectively the proposed solution

### B: Separate Targeted Dataset

Enhance first, create a separate dataset for just the enhanced areas, run both evals against only the targeted dataset.

- Pro: Focused comparison on exactly what changed
- Con: Doesn't catch regressions in existing behavior
- Con: eval harness doesn't support multiple datasets per eval.yaml
- Rejected: not feasible with current harness architecture

### C: Do Nothing (Current State)

Rely on the existing dataset and accept that some improvements won't be measured.

- Pro: Simple, no changes needed
- Con: Undermines the purpose of measure-enhance-measure

## Scope

This would extend `/skill:measure` with a "targeted eval" step between enhancement and re-evaluation. The comparison script and report format stay the same. The main new work is the diff analysis and targeted case generation.

## Dependencies

- Requires `/eval-dataset` or similar to support generating cases for specific patterns
- Requires diffing the enhancement output to know what changed (the enhancer already produces a "What Changed" table)

## Open Questions

- How to generate targeted test cases from an enhancement diff? Could invoke `/eval-dataset` with a hint about which patterns to focus on.
- Should the targeted cases be marked (e.g., with a tag in the case metadata) so future runs can distinguish original from targeted?
- What's the right number of targeted cases per enhanced pattern? Probably 1-2 per pattern, keeping the dataset growth bounded.
