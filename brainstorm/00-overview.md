# Brainstorm Overview

Last updated: 2026-07-14

## Sessions

| # | Date | Topic | Status | Spec | Issue |
|---|------|-------|--------|------|-------|
| 01 | 2026-05-04 | skill-eval | spec-created | 002 | - |
| 02 | 2026-05-11 | 9-principles | parked | - | - |
| 03 | 2026-05-27 | eval-automation | implemented | 003 | - |
| 04 | 2026-05-28 | targeted-eval-dataset | active | 004 | - |
| 05 | 2026-07-14 | three-layer-linting | active | - | - |
| 06 | 2026-07-14 | eval-framework | active | - | - |
| 07 | 2026-07-14 | skill-lifecycle | active | - | - |

## Open Threads
- Should Layer 3 (substance review) be a flag on `skill:check --deep` or a separate command? (from #05)
- How should the summary line change to reflect the three-layer model? (from #05)
- Should principle enrichments change quality criteria thresholds? (from #05)
- How much of the Codex eval pattern requires harness changes vs. plugin changes? (from #06)
- Should the four goal categories be configurable per skill? (from #06)
- How to handle negative control eval type in the current harness? (from #06)
- Should `skill:scan` be integrated into `skill:check` or kept separate? (from #07)
- How to handle false positives in security scanning? (from #07)
- How many test prompts per category for `skill:describe`? (from #07)
- Should `skill:describe` test against multiple models? (from #07)

## Parked Ideas
- 9 Principles integration (#02)
  Reason: Superseded by #05 (three-layer-linting), which incorporates the 9 principles into a broader framework
