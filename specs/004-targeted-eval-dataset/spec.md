# Feature Specification: Targeted Eval Dataset for Enhancement Coverage

**Feature Branch**: `004-targeted-eval-dataset`
**Created**: 2026-05-28
**Status**: Draft
**Input**: User description: "After enhancing a skill, generate targeted test cases covering the changed areas, merge them into the existing dataset, then run baseline and enhanced evals against the combined dataset for a fair comparison."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Measure with Targeted Coverage (Priority: P1)

A skill author runs `/skill:measure` on their SKILL.md. The enhancer strengthens three patterns (e.g., adds Known Gotchas, improves Template Scaffold, adds Execution Checklist). The existing eval dataset has test cases that exercise general skill behavior but none that specifically test gotcha handling, template output, or step-by-step execution flow. The author wants the comparison to reflect the improvement in those specific areas, not just the areas the original dataset happened to cover.

**Why this priority**: This is the core value. Without targeted coverage, `/skill:measure` can report "no change" when the skill genuinely improved because the dataset doesn't exercise the enhanced areas.

**Independent Test**: Run `/skill:measure path/to/SKILL.md` on a skill where the enhancer adds patterns not covered by the existing dataset. Verify that new test cases are generated for the enhanced areas, merged into the dataset, and both baseline and enhanced evals use the combined dataset.

**Acceptance Scenarios**:

1. **Given** a skill where `/skill:enhance` adds a Known Gotchas pattern, **When** `/skill:measure` runs the full loop, **Then** at least one new test case is generated that exercises gotcha-handling behavior, and the comparison report shows scores for that test case.
2. **Given** a skill where `/skill:enhance` reports "already optimal", **When** `/skill:measure` runs, **Then** no targeted test cases are generated (nothing changed) and the workflow behaves as before.
3. **Given** a skill with an existing dataset of 5 cases, **When** `/skill:measure` generates 2 targeted cases, **Then** both baseline and enhanced evals run against all 7 cases, and the comparison report covers all 7.

---

### User Story 2 - Review Targeted Cases Before Eval (Priority: P2)

A skill author wants to review the targeted test cases before they run against the skill. They want to confirm the generated cases actually test the enhanced areas and aren't redundant with existing cases.

**Why this priority**: Targeted cases are auto-generated. A quick review prevents wasted eval cycles on bad test cases.

**Independent Test**: Run the targeted case generation step in isolation and inspect the generated cases before any eval runs.

**Acceptance Scenarios**:

1. **Given** targeted test cases have been generated, **When** the author reviews them, **Then** each case includes a note explaining which enhancement it targets (e.g., "Tests gotcha handling added by enhancement").
2. **Given** a generated targeted case that duplicates an existing case, **When** the author reviews, **Then** they can remove or skip duplicates before the eval runs.

---

### Edge Cases

- What happens when the enhancement diff is empty (enhancer made no changes)? No targeted cases should be generated. The workflow proceeds with the existing dataset only.
- What happens when the enhancement touches areas that the existing dataset already covers well? The targeted case generator should detect overlap and avoid generating redundant cases.
- What happens when `/eval-dataset` is not available? The workflow should fall back to the existing dataset with a warning that targeted coverage could not be generated.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `/skill:measure` MUST analyze the enhancement diff to identify which patterns were added or strengthened.
- **FR-002**: `/skill:measure` MUST generate targeted test cases that exercise the specific patterns identified in the enhancement diff.
- **FR-003**: Targeted test cases MUST be merged into the existing `eval/cases/` directory before either eval run begins.
- **FR-004**: Both baseline (pre-enhancement) and enhanced (post-enhancement) evals MUST run against the same combined dataset (original + targeted cases).
- **FR-005**: Each targeted test case MUST include metadata indicating which enhancement it targets (for traceability and review).
- **FR-006**: When `/skill:enhance` reports "already optimal" (no changes made), targeted case generation MUST be skipped entirely.
- **FR-007**: Targeted case generation MUST NOT modify or remove existing test cases in the dataset.
- **FR-008**: The number of targeted cases generated MUST be bounded (1-2 per enhanced pattern, configurable).
- **FR-009**: `/skill:measure` MUST report how many targeted cases were generated and which enhancements they cover.

### Key Entities

- **Enhancement Diff**: The set of patterns that `/skill:enhance` added or strengthened, extracted from the enhancer's "What Changed" output table.
- **Targeted Test Case**: A test case generated specifically to exercise a pattern that was enhanced, stored in the same format as existing eval cases.
- **Combined Dataset**: The merged set of original test cases plus targeted test cases, used for both baseline and enhanced eval runs.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: When `/skill:enhance` improves N patterns, the combined dataset contains at least N new test cases that target those specific patterns.
- **SC-002**: The comparison report after a targeted-coverage run shows score changes for the enhanced areas (not all N/A or unchanged when the skill genuinely improved).
- **SC-003**: Targeted case generation adds no more than 30 seconds to the `/skill:measure` workflow.
- **SC-004**: Existing test cases remain unmodified after targeted cases are merged.

## Assumptions

- The `/skill:enhance` "What Changed" table is parseable and reliably identifies which patterns were modified.
- The `/eval-dataset` skill (or a similar mechanism) can generate test cases scoped to specific skill patterns when given a hint.
- The eval harness runs all cases in the `eval/cases/` directory without requiring explicit registration of new cases.
- The eval case directory format supports adding new case directories alongside existing ones without conflicts.
