# Brainstorm: Skill Evaluation and Enhancement Measurement

**Date:** 2026-05-04
**Status:** active

## Problem Framing

When `skill:enhance` improves a user's SKILL.md, we claim it got better. But there's no way to verify that claim quantitatively. We need a method to measure a skill's behavioral quality before and after enhancement, so we can answer: "Did our enhancement methodology actually help this skill do its job better, and by how much?"

This is distinct from structural pattern checking (`skill:check`), which evaluates whether authoring patterns are present. Behavioral evaluation tests whether the skill produces good outputs when invoked with realistic inputs.

## Context

Two key resources informed this brainstorm:

- **Anthropic's "Demystifying Evals for AI Agents"**: Covers eval methodology, dataset design, grader types (code-based, model-based, human), pass@k/pass^k metrics, and phased eval roadmaps. Key insight: grade outcomes over paths, since agents regularly find valid approaches that eval designers didn't anticipate.

- **agent-eval-harness** (github.com/opendatahub-io/agent-eval-harness): A Claude Code plugin with 7 skills (eval-setup, eval-analyze, eval-dataset, eval-run, eval-review, eval-optimize, eval-mlflow) that provides a complete agent/skill evaluation pipeline. It analyzes skill shape, generates datasets, runs evals with configurable judges, supports A/B comparison between skill versions, and logs results to MLflow.

## Approaches Considered

### A: Standalone Eval Skills in This Plugin

Build new skills (`skill:eval-dataset`, `skill:eval`, `skill:eval-score`) directly in this plugin. Generate datasets, run evaluations, score results, and compare before/after enhancement all within the plugin.

- Pros: Self-contained, no external dependencies, full control over the eval pipeline
- Cons: Massive overlap with agent-eval-harness, duplicates existing infrastructure, the eval machinery would drift apart from the harness over time, significant scope expansion for a plugin focused on skill authoring

### B: Integration Bridge

This plugin provides skill-domain-specific judges, dataset templates, and scoring rubrics that plug INTO the agent-eval-harness. A thin `skill:eval` command generates harness-compatible eval.yaml and delegates actual execution to the harness.

- Pros: Leverages existing harness infrastructure, clean separation of concerns, plugin stays focused
- Cons: Still requires building and maintaining integration code, couples the plugin to the harness's schema evolution, the bridge skill is thin glue that may not justify its own maintenance

### C: Documentation Only (Chosen)

No new skills. Document the "measure-enhance-measure" workflow in the README, showing how to use the agent-eval-harness alongside this plugin. The harness handles all evaluation (analyze, dataset, run, compare). This plugin handles enhancement (`skill:enhance`). Users chain them together following the documented workflow.

- Pros: Zero overlap, clean separation, no new code to maintain, leverages each tool's strength
- Cons: Requires users to install and learn two plugins, no automated orchestration of the full cycle

## Decision

**Chosen approach: C (Documentation Only)**

The agent-eval-harness already provides the complete eval pipeline: skill analysis, dataset generation, evaluation runs with configurable judges, A/B comparison between versions, and MLflow integration. Building any of that into this plugin would duplicate existing, well-maintained infrastructure.

The measure-enhance-measure workflow is a sequential chain:

1. `eval-analyze` on the user's skill (harness generates eval.yaml + dataset schema)
2. `eval-dataset` to create test cases for the skill's domain (harness)
3. `eval-run` to get baseline scores (harness)
4. `skill:enhance` to improve the skill (this plugin)
5. `eval-run` again on the enhanced version (harness)
6. Compare results (harness already supports version comparison)

This plugin's unique contribution is step 4. Everything else belongs to the harness. The right integration point is documentation, not code.

## Key Requirements

- Add a section to the README documenting the measure-enhance-measure workflow
- Show concrete examples using both plugins together
- Reference the agent-eval-harness installation and setup
- Explain what eval.yaml judges are most relevant for skill quality evaluation

## Open Questions

- Should the documentation include a recommended set of judges specifically tuned for skill quality evaluation (e.g., "did the skill's error handling improve?", "is the output more actionable?")?
- If the harness evolves its plugin API, could a future version support "eval profiles" that this plugin could ship as data (no code) for skill-specific evaluation?
- Would it be valuable to ship a sample eval.yaml in this plugin's repo as a reference for users who want to evaluate skill:check or skill:enhance themselves?

---

## Revisit: 2026-05-26

### Updated Problem Framing

The original decision (Approach C, documentation-only) was correct but never implemented. The documentation for the measure-enhance-measure workflow still needs to be written. Additionally, the focus has shifted: rather than evaluating cc-skill's own skills, the primary use case is helping users measure how much skill:enhance improves *their* skills. Both plugins (cc-skill and agent-eval-harness) can be assumed installed.

### Approaches Reconsidered

The three original approaches were revisited. More complex options (shipping eval configs, building orchestration skills, designing eval profile patterns) were considered and rejected as overengineering. The documentation approach remains the right call since the harness already provides the full eval pipeline and cc-skill's only contribution is the enhancement step.

### Updated Decision

Implement the original Approach C decision: write the documentation. Specifically:

**Deliverable:** A new section in cc-skill's README documenting the measure-enhance-measure workflow.

**Contents:**
1. The 6-step workflow: eval-analyze, eval-dataset, eval-run (baseline), skill:enhance, eval-run (enhanced), compare
2. Prerequisites (both plugins installed)
3. A concrete walkthrough showing the full loop on a real skill, with sample output at each step
4. Notes on which judges are useful for measuring skill quality improvement

**Out of scope:**
- No new skills or code in cc-skill
- No shipped eval.yaml or eval configs
- No changes to agent-eval-harness
- Not evaluating cc-skill's own skills (separate concern)

### Open Questions

- Which real skill to use for the walkthrough example?
- Should the walkthrough show actual judge output, or simplified/representative output?
