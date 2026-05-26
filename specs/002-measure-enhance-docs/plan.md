# Implementation Plan: Measure-Enhance-Measure Workflow Documentation

**Branch**: `002-measure-enhance-docs` | **Date**: 2026-05-26 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/002-measure-enhance-docs/spec.md`

## Summary

Add a "Measuring Skill Improvement" section to the cc-skill README that documents the 6-step measure-enhance-measure workflow. This combines the agent-eval-harness plugin (for evaluation) with cc-skill's `skill:enhance` (for improvement) to let users quantitatively measure how much their skill improves. The section includes a concrete walkthrough with representative output and guidance on selecting judges for skill quality evaluation.

## Technical Context

**Language/Version**: Markdown (documentation only)
**Primary Dependencies**: N/A (no code changes)
**Storage**: N/A
**Testing**: Manual review (documentation correctness)
**Target Platform**: GitHub README rendering
**Project Type**: Documentation addition to existing Claude Code plugin
**Performance Goals**: N/A
**Constraints**: Must not introduce new code, skills, or eval config files (FR-007)
**Scale/Scope**: Single file change (README.md), approximately 150-250 lines added

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Constitution is a blank template with no project-specific principles. No gates to evaluate. Passes by default.

## Project Structure

### Documentation (this feature)

```text
specs/002-measure-enhance-docs/
├── spec.md              # Feature specification
├── plan.md              # This file
├── research.md          # Phase 0: research on walkthrough content
└── tasks.md             # Phase 2 output (created by /speckit-tasks)
```

### Source Code (repository root)

```text
README.md                # Only file modified by this feature
```

**Structure Decision**: Single file modification. No new directories, no data model, no contracts. The entire deliverable is a new section appended to the existing README.md.

## Design Decisions

### D1: README Section Placement

The new "Measuring Skill Improvement" section goes after the existing "How the Enhancer Works" section. This follows the natural reading flow: learn what the tools do, then learn how to measure their effectiveness.

### D2: Walkthrough Skill Selection

The walkthrough uses a hypothetical but realistic skill (a simplified TDD skill) rather than a specific real skill from a public plugin. This avoids coupling the documentation to a specific external project's skill file and keeps the example self-contained.

### D3: Representative Output Format

Sample outputs are simplified and representative rather than verbatim tool output. Each step shows the command invocation followed by a condensed version of what the user would see, focusing on the key information (scores, pattern counts, improvement deltas).

### D4: Judge Guidance Scope

The judges section recommends 3 categories of judges relevant to skill quality:
1. **Structural completeness judges** (inline checks): verify output contains expected sections, pattern coverage
2. **Behavioral quality judges** (LLM judges): evaluate whether the skill produces actionable, clear guidance
3. **Improvement delta judges** (pairwise comparison): compare before/after eval runs to measure net change

These map to the eval-harness's judge types (inline check, LLM, pairwise) without prescribing specific judge implementations.

### D5: Section Structure

The README section is structured as:
1. Prerequisites (short paragraph)
2. The Workflow (numbered 6-step list with descriptions)
3. Walkthrough (step-by-step with commands and sample output)
4. Choosing Judges (guidance on judge categories)
5. Tips (edge cases: already-optimal skills, score decreases)
