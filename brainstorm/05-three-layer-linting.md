# Brainstorm: Three-Layer Skill Linting

**Date:** 2026-07-14
**Status:** active

## Problem Framing

The current `skill:check` evaluates skills against 14 authoring patterns in a single pass. Bilgin Ibryam's "5 Software Disciplines That Keep AI Skills From Rotting" (July 2026) proposes a three-layer linting model that maps directly to different depths of analysis. Our checker currently operates at layer 2 (best-practice review) but skips layer 1 (deterministic validation) and layer 3 (substance review). Meanwhile, his previous post ("9 Principles That Separate Useful Skills from Markdown Essays") identified design principles that sit above patterns, three of which are genuinely new checks not covered by our 14 patterns.

The goal: make `skill:check` the most thorough skill linting tool available by adopting the three-layer model and integrating the principle-level checks.

## Source Material

- Bilgin Ibryam, "5 Software Disciplines That Keep AI Skills From Rotting" (generativeprogrammer.com, July 2026)
- Bilgin Ibryam, "9 Principles That Separate Useful Skills from Markdown Essays" (generativeprogrammer.com, earlier 2026)
- agentskills.io "Best practices for skill creators"
- Brainstorm #02 in this project (gap analysis of 9 principles vs. 14 patterns)

## Approaches Considered

### A: Expand Patterns to ~17

Add the 3 genuinely new principle-level checks (P3: Process over prose, P5: Anticipate the excuse, P7: Stay in scope) as flat new patterns 15-17 in the knowledge base.

- Pros: Minimal structural change, backward compatible
- Cons: Doesn't capture the altitude difference between patterns and principles, misses the deterministic and substance layers entirely

### B: Two-Tier Model (Patterns + Principles)

Keep 14 patterns and add a separate "Principle Alignment" evaluation with different vocabulary (`aligned / partial / gap`). This was the approach proposed in brainstorm #02.

- Pros: Clean conceptual separation, acknowledges that principles operate at a different level
- Cons: Still only one layer of analysis depth, misses deterministic validation and substance review

### C: Three-Layer Linting (Chosen)

Adopt Bilgin's explicit three-layer model:

**Layer 1 (Deterministic):** Schema and structural validation. Fast, cheap, binary pass/fail checks.
- YAML frontmatter presence and validity
- Required fields: `name`, `description`
- Description character count vs. known limits (1024 for Agent Skills spec, 1536 for Claude Code's description + when_to_use combined)
- Frontmatter field validation (known fields, types)
- Line count thresholds (500-line body warning)
- Token budget estimate (5000-token body threshold per agentskills.io)
- File structure checks (scripts/ directory, reference files, companion files)

**Layer 2 (Best-Practice):** Pattern and principle evaluation. The current checker's core, expanded.
- 14 existing patterns (unchanged)
- 3 new patterns from the 9 principles:
  - Pattern 15: **Process over Prose** (P3). Detection: "Would a junior engineer reading this know what to do next?" Checks whether the skill is a workflow with actionable steps or an essay describing concepts. Different from Execution Checklist, which checks for numbered steps; this checks whether the entire skill is fundamentally actionable.
  - Pattern 16: **Anticipate the Excuse** (P5). Detection: Rebuttal tables near non-negotiable rules. Checks whether hard rules have pre-written counters to common rationalizations. Different from Known Gotchas, which catches external surprises; this catches internal ones (the agent arguing itself out of compliance).
  - Pattern 17: **Stay in Scope** (P7). Detection: Scope-bounding instructions inside the skill body. Checks whether the skill constrains what the agent touches once running. Different from Exclusion Clause, which operates at metadata level (should the skill fire?); this operates at runtime level (what should the skill touch?).
- Principle alignment assessment for the remaining 6 principles (P1, P2, P4, P6, P8, P9) as enrichments to existing pattern evaluations, not separate checks
- agentskills.io guidelines integrated where they add specificity:
  - "Add what the agent lacks, omit what it knows" (strengthens Context Budget)
  - "Provide defaults, not menus" (strengthens Control Tuning)
  - "Favor procedures over declarations" (supports Process over Prose)

**Layer 3 (Substance):** Model-as-senior-engineer review. Expensive, qualitative, scheduled by risk.
- "Does this skill do something sensible for its stated purpose?"
- "Could the instructions produce harmful output if followed literally?"
- "Are the examples realistic or contrived?"
- "Does the workflow have dead ends or unreachable branches?"
- Runs as an optional pass (flag or separate invocation) since it requires LLM inference

- Pros: Comprehensive coverage across all three analysis depths, maps to established framework, positions skill:check as best-in-class
- Cons: Layer 3 adds cost and non-determinism. Substance review quality depends on the reviewing model.

## Decision

**Chosen approach: C (Three-Layer Linting)**

The three layers map to different cost/value tradeoffs:
- Layer 1 runs on every change (milliseconds, deterministic)
- Layer 2 runs on every check invocation (current behavior, expanded)
- Layer 3 runs on demand (expensive, for high-stakes or pre-sharing review)

## Key Requirements

### Changes to `skill:check`

1. **Add Layer 1 output** before the pattern checklist. Report deterministic checks as a pass/fail list. Any failures here are hard blockers (not judgment calls).

2. **Expand Layer 2** from 14 to 17 patterns. Add Process over Prose, Anticipate the Excuse, Stay in Scope with detection signals, quality criteria, and improvement guidance matching the existing pattern format.

3. **Enrich existing patterns** with principle-level signals:
   - Pattern 1 (Activation Metadata): Add character budget check against 1024/1536 limits. Add "routing rule vs. summary" distinction from P1.
   - Pattern 3 (Context Budget): Add "omit what the model knows" signal from agentskills.io.
   - Pattern 5 (Control Tuning): Add "defaults not menus" signal. Add "match specificity to fragility" from agentskills.io.
   - Pattern 6 (Explain-the-Why): Add "when NOT to explain" for fragile steps (narrow imperative is better) from P4.
   - Pattern 13 (Utility Bundle): Add "detect deterministic steps written as LLM prose" from P6.

4. **Add Layer 3 as optional** (`--deep` flag or separate invocation). Output is a narrative assessment, not a table. The substance review should ask 4-5 senior-engineer questions and produce a structured verdict.

5. **Add lifecycle signals** (limited, from P8/P9):
   - P8 (Skills decay): Check for lifecycle metadata (last-tested date, owner, version). Mark as "limited: cannot observe runtime behavior."
   - P9 (Run before you ship): Check for evidence of real-run testing (gotchas that reference observed behavior, rebuttals citing actual runs, scripts promoted from observed patterns). Mark as "limited: inferred from content signals."

### Changes to `skill:enhance`

6. **Enhance against 17 patterns** instead of 14. The enhancer must be able to:
   - Restructure prose into workflow (for P3/Process over Prose)
   - Generate rebuttal tables (for P5/Anticipate the Excuse)
   - Add scope-bounding instructions (for P7/Stay in Scope)

### Changes to knowledge base

7. **Update `skill-authoring-patterns.md`** with the 3 new patterns and enriched detection signals for existing patterns.

### Output format evolution

8. The checker output grows from one table to three sections:
   ```
   ## Layer 1: Schema Validation
   [pass/fail list]

   ## Layer 2: Pattern & Principle Assessment
   [17-pattern table, same format as today but expanded]

   ## Layer 3: Substance Review (if --deep)
   [narrative assessment]
   ```

## Open Questions

- Should Layer 3 (substance review) be a flag on `skill:check --deep` or a separate command like `skill:review`?
- How should the summary line change to reflect the three-layer model? Currently it's "A of B patterns present, C strong, D improvements suggested."
- Should the principle enrichments to existing patterns change the quality criteria thresholds? (e.g., Activation Metadata can't be "strong" without meeting the character budget check)
- What's the right interaction between this plugin's Layer 3 and the prompt plugin's analysis? They serve similar "model reads the skill" functions but check different things.
