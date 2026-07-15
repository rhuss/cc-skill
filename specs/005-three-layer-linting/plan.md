# Implementation Plan: Three-Layer Skill Linting

**Branch**: `005-three-layer-linting` | **Date**: 2026-07-14 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/005-three-layer-linting/spec.md`

## Summary

Expand the `skill:check` and `skill:enhance` Claude Code skills from a single-layer 14-pattern evaluation to a three-layer linting model: Layer 1 (deterministic schema validation), Layer 2 (17-pattern best-practice assessment with principle enrichments), and Layer 3 (optional substance review via `--deep` flag). This requires updating three Markdown files and one JSON manifest, with no compiled code, build system, or external dependencies.

## Technical Context

**Language/Version**: Markdown (SKILL.md skill definitions), no compiled language
**Primary Dependencies**: Claude Code plugin system (skill loading, YAML frontmatter routing)
**Storage**: N/A (all content is Markdown files read by the LLM at invocation time)
**Testing**: Manual validation by running `/skill:check` and `/skill:enhance` against real SKILL.md files
**Target Platform**: Claude Code CLI / IDE extensions
**Project Type**: Claude Code plugin (Markdown skills + knowledge base)
**Performance Goals**: N/A (skills are LLM-interpreted Markdown, no runtime performance concerns)
**Constraints**: Skills must fit within Claude Code's context window; knowledge file should remain scannable
**Scale/Scope**: 4 files to modify (knowledge base, checker, enhancer, plugin manifest)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Constitution is a template with no project-specific gates defined. No violations to check.

## Project Structure

### Documentation (this feature)

```text
specs/005-three-layer-linting/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

```text
skill/
├── .claude-plugin/
│   └── plugin.json               # Version bump: 1.1.0 → 1.2.0
├── CLAUDE.md                     # Plugin conventions (update "14" → "17")
├── knowledge/
│   └── skill-authoring-patterns.md  # Add 3 new patterns, enrich 5 existing
└── skills/
    ├── checker/
    │   └── SKILL.md              # Add Layer 1, Layer 3, expand to 17 patterns
    ├── enhancer/
    │   └── SKILL.md              # Expand to 17 patterns, add enhancement strategies
    └── measure/
        └── SKILL.md              # Update pattern count references (14 → 17)
```

**Structure Decision**: Existing single-plugin structure. No new files or directories needed. All changes are modifications to existing files.

## Implementation Approach

### Change 1: Knowledge Base (`skill-authoring-patterns.md`)

This is the foundation change. Both checker and enhancer read this file.

**Add 3 new patterns** at the end, following the existing format:

1. **Pattern 15: Process over Prose** (new category: "Workflow Quality")
   - Applicability: Universal
   - Detection: Numbered steps, imperative verbs, decision points, conditional branches
   - Strong: Every section is actionable; a junior engineer knows what to do next
   - Present: Some workflow steps exist but mixed with descriptive prose
   - Guidance: Restructure declarative text into numbered procedures with clear entry/exit conditions

2. **Pattern 16: Anticipate the Excuse** (category: "Instruction Calibration")
   - Applicability: Skills with non-negotiable rules or hard constraints
   - Detection: Rebuttal tables, "you might think... but" constructions, pre-answered objections near mandatory rules
   - Strong: Every MUST/NEVER rule has pre-written counters to 2+ likely rationalizations
   - Present: Some rebuttal content exists but does not cover all hard rules
   - Guidance: For each non-negotiable rule, list the 2-3 most likely agent rationalizations and provide explicit rebuttals

3. **Pattern 17: Stay in Scope** (category: "Workflow Control")
   - Applicability: Skills that modify files or system state
   - Detection: Scope-bounding instructions, file/directory constraints, "do NOT touch" declarations, explicit boundaries on what the agent may modify
   - Strong: Explicit positive constraints (what to touch) AND negative constraints (what not to touch) with rationale
   - Present: Some scope mention exists but boundaries are vague or incomplete
   - Guidance: Add explicit scope constraints listing allowed and disallowed targets

**Enrich 5 existing patterns** with additional detection signals:

1. **Pattern 1 (Activation Metadata)**: Add character budget check (1024 Agent Skills, 1536 Claude Code description+when_to_use). Add "routing rule vs. summary" distinction.
2. **Pattern 3 (Context Budget)**: Add "omit what the model knows" signal from agentskills.io.
3. **Pattern 5 (Control Tuning)**: Add "defaults not menus" signal. Add "match specificity to fragility."
4. **Pattern 6 (Explain-the-Why)**: Add "narrow imperative for fragile steps" (when NOT to explain).
5. **Pattern 13 (Utility Bundle)**: Add "detect deterministic steps written as LLM prose."

### Change 2: Checker SKILL.md

**Add Layer 1 section** (new Step between current Step 2 and Step 3):
- Insert a "Step 2.5: Layer 1 Schema Validation" that runs deterministic checks before pattern evaluation
- Checks: frontmatter presence, required fields, description length, known field validation, body line count, token budget estimate
- Each check produces PASS/WARN/FAIL with remediation hint
- Output format: pass/fail list under "## Layer 1: Schema Validation" heading

**Expand Layer 2** (modify current Step 3):
- Change "14 patterns" references to "17 patterns"
- The checker already loads patterns from the knowledge file dynamically, so adding patterns there should auto-expand evaluation
- Add lifecycle signals subsection after the pattern table

**Add Layer 3** (new step after pattern evaluation):
- New step gated on `--deep` flag
- Produces narrative assessment with labeled subsections: Purpose Sensibility, Harmful Output Risk, Example Realism, Workflow Completeness
- Overall Verdict line with pass/concern/fail rating
- Only runs when `--deep` is present in the argument string

**Update argument parsing** (Step 1):
- Parse `--deep` flag from the argument string alongside file path

**Update summary line** (final step):
- Change format to: `Layer 1: X/Y passed | A of B patterns present, C strong | [Deep: verdict]`

**Update description** in YAML frontmatter:
- Change "14 skill-authoring patterns" to "17 skill-authoring patterns"
- Add mention of three-layer model and `--deep` flag

### Change 3: Enhancer SKILL.md

**Expand pattern count** (Steps 2-5):
- Change "14 patterns" references to "17 patterns"
- The enhancer already loads patterns from the knowledge file, so the new patterns will be picked up automatically

**Add enhancement strategies for new patterns** (Step 4):
- Process over Prose: Restructure descriptive sections into numbered workflow steps with entry/exit conditions
- Anticipate the Excuse: Identify MUST/NEVER rules and generate rebuttal tables with 2-3 rationalizations each
- Stay in Scope: Add scope-bounding section with explicit positive and negative constraints

**Update description** in YAML frontmatter:
- Change "14 skill-authoring patterns" to "17 skill-authoring patterns"

### Change 4: Plugin Manifest and Conventions

**plugin.json**: Bump version from 1.1.0 to 1.2.0, update description to mention 17 patterns.

**skill/CLAUDE.md**: Update "14 skill-authoring patterns" to "17 skill-authoring patterns" in the Knowledge Loading section.

**skill/skills/measure/SKILL.md**: Update any references to "14 patterns" to "17 patterns."

## Complexity Tracking

No constitution violations to justify. All changes are additive modifications to existing Markdown files.
