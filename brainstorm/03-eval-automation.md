# Brainstorm: Automated Evaluation Flow for Skill Enhancement

**Date:** 2026-05-27
**Status:** active

## Problem Framing

The measure-enhance-measure workflow (documented in README, brainstorm #01) requires 6 manual steps across two plugins. While the documentation makes the process clear, running it manually is tedious, especially the comparison step where users must interpret two separate eval run results. We want to automate the repeatable parts while preserving user control over setup decisions.

## Context

- Brainstorm #01 shipped documentation-only (the 6-step workflow in the README)
- The 6 steps split into two natural phases:
  - **Setup** (steps 1-2): `eval-analyze` + `eval-dataset`, done once per skill, needs human judgment
  - **Loop** (steps 3-6): `eval-run` + `skill:enhance` + `eval-run` + compare, repeatable
- The comparison step is the most painful: no automated delta reporting exists
- Both cc-skill and agent-eval-harness plugins can be assumed installed
- Nested `claude -p` sessions are risky (don't share plugins/settings, can't handle interactive prompts, fragile output parsing)

## Approaches Considered

### A: Scripts Only

Two shell scripts in cc-skill's `scripts/` directory:
1. `enhance-loop.sh` orchestrates the 3 eval steps via `claude -p`
2. `compare-runs.sh` does pure data processing (read summary.yaml, compute deltas)

- Pros: Simplest, no new skills, scripts are testable
- Cons: `claude -p` is fragile for nested sessions (plugins/settings not shared, interactive prompts can't be handled, output format may change). This is the dealbreaker.

### B: Skill + Script Hybrid (Chosen)

1. `skill:measure` (new skill) orchestrates the loop inside the same Claude Code session, invoking `/eval-run` and `/skill:enhance` as skills directly
2. `scripts/compare-runs.sh` handles comparison as pure data processing

- Pros: Orchestration runs in the same session (no nested CLI), handles errors gracefully, comparison is deterministic and reusable standalone
- Cons: New skill to maintain, cross-plugin dependency (invokes harness skills)

### C: Two New Skills

1. `skill:measure` for orchestration
2. `skill:compare` for LLM-powered comparison analysis

- Pros: Richer comparison output (Claude can explain why scores changed)
- Cons: More expensive (LLM inference for deterministic work), non-deterministic comparison is harder to test, two skills to maintain

## Decision

**Chosen approach: B (Skill + Script Hybrid)**

The key insight: orchestration needs to run in the same Claude Code session to avoid nested CLI problems, but comparison is pure data processing that belongs in a script.

**What gets built:**

1. **`skill:measure`** (new skill in cc-skill):
   - Invokes `/eval-run` to get baseline scores
   - Invokes `/skill:enhance` to improve the skill
   - Invokes `/eval-run` again on the enhanced version
   - Calls `scripts/compare-runs.sh` with both run directories
   - Presents the delta report to the user

2. **`scripts/compare-runs.sh`** (new script in cc-skill):
   - Reads `summary.yaml` from two eval run directories
   - Computes per-judge deltas (score diff, pass rate diff)
   - Prints a summary table to terminal
   - Saves a detailed markdown report alongside the runs
   - Callable standalone (users can compare any two runs without the skill)

**User workflow (3 interactions instead of 6):**

1. Setup (once): `/eval-analyze` then `/eval-dataset` (existing harness commands)
2. Enhance loop: `/skill:measure path/to/SKILL.md` (new, automates steps 3-5)
3. Results: comparison report printed to terminal + saved as markdown

## Key Requirements

- `skill:measure` must run in the same Claude Code session (no nested `claude -p`)
- `compare-runs.sh` must produce both terminal output and a markdown report file
- `compare-runs.sh` must be callable standalone (not only through the skill)
- The comparison must show per-judge deltas with clear improvement/regression indicators
- Setup steps (eval-analyze, eval-dataset) remain manual and unchanged
- No changes to the agent-eval-harness plugin

## Open Questions

- How does `skill:measure` locate the eval run output directories? Does it parse eval-run's output, or does the harness write to a known location?
- Should `compare-runs.sh` use `yq` for YAML parsing (user prefers yq per CLAUDE.md), or should it use Python for richer processing?
- Should the comparison report include a "net improvement score" (single number summarizing overall change)?
- What happens if eval-run fails mid-way through the loop? Should skill:measure save partial results?
