# Brainstorm: Eval Framework Improvement

**Date:** 2026-07-14
**Status:** active

## Problem Framing

The current `skill:measure` orchestrates a measure-enhance-measure loop using the agent-eval-harness. It works, but the evaluation methodology itself is basic: the harness runs eval cases, judges score them, and `compare-runs.sh` computes deltas. There's no structured way to distinguish between "the skill produced the right output" (outcome) vs. "the skill followed the right process" (process) vs. "the output follows conventions" (style) vs. "it didn't waste tokens or thrash" (efficiency).

OpenAI's Codex eval pattern (documented at developers.openai.com/blog/eval-skills) provides a more rigorous framework: two-layer scoring (deterministic + model-assisted rubric), four goal categories, typed prompt datasets with negative controls, and structured output schemas. Adopting this pattern would make our eval methodology significantly more precise about what "improvement" means.

## Source Material

- OpenAI, "Eval Skills" (developers.openai.com/blog/eval-skills)
- Bilgin Ibryam, "5 Software Disciplines That Keep AI Skills From Rotting" (section on Skill Evals)
- agentskills.io "Best practices for skill creators" (references "Evaluating skill output quality")
- Existing brainstorms #01, #03, #04 in this project

## Approaches Considered

### A: Better Criteria Only

Improve the judge rubrics with the four-goal model (outcome, process, style, efficiency) without changing the tooling. Ship improved eval.yaml templates and judge prompt examples.

- Pros: No tool changes, immediate value
- Cons: Doesn't address structural gaps (no deterministic grading layer, no typed datasets, no structured schemas)

### B: Adopt the Codex Eval Pattern (Chosen)

Restructure the evaluation methodology around the Codex pattern's key innovations:

**Two-layer scoring:**
- Layer 1 (Deterministic graders): Binary pass/fail checks on concrete outcomes. Did the checker produce a pattern table? Did the enhancer preserve frontmatter? Did the output match the expected template structure? These parse eval run artifacts (traces, output files) without LLM inference.
- Layer 2 (Model-assisted rubric): A structured rubric prompt with enforced JSON schema. The model evaluates qualitative criteria (is the analysis insightful? are the enhancement suggestions proportionate?) and returns structured scores, not free-text opinions.

**Four goal categories:**
- Outcome: Did the skill complete its stated task? (e.g., did skill:check produce a complete pattern checklist?)
- Process: Did the skill follow its documented procedure? (e.g., did it load the knowledge file before evaluating?)
- Style: Does the output follow conventions? (e.g., are notes specific rather than generic? Is the template format correct?)
- Efficiency: Did it complete without thrashing? (e.g., reasonable token usage, no unnecessary file reads, no repeated operations)

**Typed prompt datasets:**
- Explicit invocation: "Run skill:check on this SKILL.md" (tests direct usage)
- Implicit invocation: "How good is this skill?" (tests autonomous selection via description)
- Contextual invocation: "I need to review a skill before sharing it with the team" (tests trigger in noisy context)
- Negative control: "Write a new skill for database migrations" (tests that skill:check does NOT fire)

**Structured output schemas:**
- Eval rubric results as JSON with `overall_pass`, `score`, and per-check results
- Consistent fields that can be compared, diffed, and tracked across runs

- Pros: Rigorous methodology, structured and comparable results, catches both quantitative and qualitative regressions
- Cons: Requires changes to eval infrastructure (eval.yaml schema, judge design), more complex to set up initially

### C: Skill-Specific Eval Profile

Ship a reusable eval configuration as a data artifact in this plugin: pre-built judges, rubrics, and dataset templates specifically for evaluating skill quality.

- Pros: Turnkey eval setup for users, addresses brainstorm #01's open question about "eval profiles as data"
- Cons: Couples to the harness's schema, needs maintenance when the harness evolves

## Decision

**Chosen approach: B (Adopt the Codex Eval Pattern)**

The key insight from Bilgin's article: "Scenario quality, repeated runs, and target-model coverage matter more than a comforting coverage number." The Codex pattern provides the structural foundation for scenario quality (typed datasets, negative controls), meaningful scoring (two-layer, four goals), and comparable results (structured schemas).

## Key Requirements

### Eval methodology changes

1. **Two-layer scoring design**: Define which checks are deterministic (Layer 1) and which need model-assisted grading (Layer 2) for each of our three skills:

   For `skill:check`:
   - Deterministic: Does the output contain a pattern table? Are all 17 patterns listed? Is the activation test section present? Does the summary line parse correctly?
   - Model-assisted: Are the pattern notes specific and actionable? Is the "present" vs. "strong" distinction applied correctly? Do the trigger scenarios exercise the description's actual content?

   For `skill:enhance`:
   - Deterministic: Does the enhanced skill preserve original frontmatter fields? Is the line count proportionate? Does the changelog table exist with the correct columns?
   - Model-assisted: Does the rewrite preserve intent? Are the pattern applications natural (not labeled)? Is the enhancement proportionate to the skill's complexity?

   For `skill:measure`:
   - Deterministic: Were all 7 steps executed? Did the comparison script produce output? Are both run directories captured?
   - Model-assisted: Is the delta report correctly interpreted? Are regressions properly flagged? Does the targeted case generation cover the right patterns?

2. **Four goal categories**: Structure eval rubrics to score each goal independently:
   - Outcome goals: Task completion, output correctness
   - Process goals: Procedure adherence, step ordering
   - Style goals: Output format, note quality, template compliance
   - Efficiency goals: Token usage, unnecessary operations, thrashing detection

3. **Typed prompt datasets**: Redesign eval case generation to produce cases in all four categories:
   - Explicit: Direct skill invocation with clear input
   - Implicit: Natural language that should trigger the skill
   - Contextual: Skill-relevant request embedded in broader context
   - Negative: Requests that should NOT trigger the skill (guards against false activation)

4. **Structured rubric schemas**: Define JSON schemas for eval results that enable automated comparison:
   ```json
   {
     "overall_pass": boolean,
     "score": integer (0-100),
     "goals": {
       "outcome": {"pass": boolean, "score": integer, "notes": string},
       "process": {"pass": boolean, "score": integer, "notes": string},
       "style": {"pass": boolean, "score": integer, "notes": string},
       "efficiency": {"pass": boolean, "score": integer, "notes": string}
     },
     "checks": [{"id": string, "pass": boolean, "notes": string}]
   }
   ```

### Changes to `skill:measure`

5. **Adopt structured scoring**: `skill:measure` should produce and consume the structured rubric schema rather than free-text judge output. The comparison script can then compute deltas per goal category.

6. **Enhanced comparison report**: `compare-runs.sh` should report per-goal-category deltas in addition to per-judge deltas. Show which dimension improved (outcome? process? style? efficiency?) rather than just an aggregate score change.

### Changes to eval infrastructure

7. **Eval case metadata**: Cases should declare their type (explicit/implicit/contextual/negative) in `annotations.yaml`. This enables per-type analysis: "the skill handles explicit invocations well but fails on implicit ones."

8. **Deterministic grader support**: Define deterministic checks as code (scripts or structured assertions) rather than judge prompts. These run without LLM inference and produce binary pass/fail.

### Principles from the Codex pattern

9. **"Every manual fix is a signal"**: When a user corrects a skill after enhancement, that correction should feed back into the eval dataset as a new test case. This is the "production teaches the test suite" loop from Bilgin's observability discipline.

10. **"Begin with fast checks, add slower ones when they reduce risk"**: Don't require all four goal categories and both scoring layers from day one. Start with deterministic graders, add model-assisted rubric when the deterministic layer is stable.

## Open Questions

- How much of this requires changes to the agent-eval-harness vs. this plugin? The two-layer scoring and structured schemas may need harness support.
- Should the four goal categories be configurable per skill, or is a fixed set correct? Different skills may weight goals differently (a read-only checker cares less about "efficiency" than an enhancer that rewrites files).
- How to handle the "negative control" eval type? The current eval harness runs skills and scores output. A negative control expects the skill to NOT run, which is a different kind of assertion.
- Should `compare-runs.sh` output the structured JSON schema in addition to the markdown report for programmatic consumption?
