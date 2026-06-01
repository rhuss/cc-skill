# Research: Targeted Eval Dataset

## R1: Enhancement Diff Table Format

**Decision**: Parse the "What Changed" markdown table from `/skill:enhance` Step 9c output.

**Rationale**: The table is already structured with consistent columns (`Pattern Applied | What was added/changed | Why`). Regex-based extraction of the "Pattern Applied" column is reliable because the enhancer formats this table consistently (enforced by its own output template). No new structured data format is needed.

**Alternatives considered**:
- Having the enhancer write a JSON sidecar file: rejected because it adds complexity to the enhancer for a single consumer.
- Comparing SKILL.md before/after with text diff: rejected because diffs show textual changes, not which patterns were applied. A renamed section looks like a big diff but may be no pattern change.

**Verified**: The enhancer's Step 9c output template (enhancer SKILL.md lines 239-280) defines the exact table format. The "Status Change" table (lines 267-272) also provides before/after status per pattern, which is useful for confirming which patterns actually improved.

## R2: Eval Case Directory Structure

**Decision**: Follow the existing convention in `eval/cases/`.

**Rationale**: Existing cases use the structure:
```
eval/cases/case-NNN-<slug>/
├── input.yaml          # Contains skill_path field
├── target-skill/
│   └── SKILL.md        # The actual skill to evaluate
└── annotations.yaml    # Expected outcomes
```

The `input.yaml` always contains `skill_path: target-skill/SKILL.md`. The `annotations.yaml` contains `description`, `expected_strong`, `expected_absent`, `expected_na`, and `min_patterns_present` fields (verified from `eval/cases/case-001-well-crafted-deploy-skill/annotations.yaml`).

Targeted cases will add a `targets_pattern` field to `annotations.yaml` for traceability. This field is not used by the existing eval harness judges, so it will not interfere with existing functionality.

**Alternatives considered**:
- Separate directory for targeted cases: rejected because the eval harness discovers cases by scanning `eval/cases/` and wouldn't find a different directory without config changes.
- Single file instead of directory per case: rejected because it breaks the existing convention and the eval harness expectation.

## R3: Numbering and Naming for Targeted Cases

**Decision**: Use `case-NNN-targeted-<pattern-slug>` naming, where NNN is one higher than the current maximum case number.

**Rationale**: Existing cases are numbered sequentially (001 through 005). Targeted cases use the same numbering scheme to stay consistent. The `targeted-` prefix makes them identifiable for deduplication checks and cleanup.

**Pattern slug mapping** (pattern name to directory-safe slug):
- "Known Gotchas" -> `known-gotchas`
- "Template Scaffold" -> `template-scaffold`
- "Execution Checklist" -> `execution-checklist`
- General rule: lowercase, spaces to hyphens, strip special characters

## R4: eval-dataset Integration

**Decision**: Invoke `/eval-dataset` with a context hint describing which pattern to target.

**Rationale**: The `/eval-dataset` skill (from agent-eval-harness) already generates eval test cases. By providing it with context about the specific pattern that was enhanced, it can generate a case that exercises that pattern specifically. The generated case will need to include a synthetic SKILL.md that is intentionally weak or strong in the targeted pattern area.

**Key constraint**: The `/eval-dataset` skill generates cases for the `skill:check` eval (based on `eval.yaml`). Targeted cases should follow the same schema (input.yaml with skill_path, a target-skill directory with SKILL.md, and annotations.yaml). The hint tells `/eval-dataset` to create a skill that specifically exercises the enhanced pattern.

**Fallback**: If `/eval-dataset` is not available (plugin not loaded), skip targeted case generation with a warning and proceed with the existing dataset only.

## R5: Review Prompt Implementation

**Decision**: Use Claude Code's conversational flow for the interactive review.

**Rationale**: Since `/skill:measure` runs within a Claude Code session, the review is a natural conversational prompt. After generating cases, the skill describes what was generated and asks the user to proceed. This matches the existing pattern where `/skill:enhance` presents changes and asks "Apply/Skip."

No special UI tooling is needed. The skill writes cases to disk during generation, presents the summary, and either keeps them (proceed) or removes them (abort) based on the user's response.
