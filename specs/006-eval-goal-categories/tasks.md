# Tasks: Eval Goal Categories

**Input**: Design documents from `specs/006-eval-goal-categories/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: User Story 2 - Reorganized Eval Judges (Priority: P1)

**Goal**: Rename all judges with goal-category prefixes and add new judges to fill coverage gaps.

**Independent Test**: Open either eval.yaml and verify every judge name starts with `outcome_`, `process_`, `style_`, or `efficiency_` and all four categories are represented.

### Implementation for User Story 2

- [x] T001 [P] [US2] Rename judges in eval/skill-check/eval.yaml: budget_check to efficiency_budget, checklist_completeness to outcome_checklist_completeness, status_validity to outcome_status_validity, note_specificity to style_note_specificity, pattern_accuracy to outcome_pattern_accuracy. Update all threshold keys to match.
- [x] T002 [P] [US2] Rename judges in eval/skill-enhance/eval.yaml: budget_check to efficiency_budget, output_completeness to outcome_output_completeness, pattern_evaluation to outcome_pattern_evaluation, frontmatter_preserved to outcome_frontmatter_preserved, changelog_specificity to style_changelog_specificity, proportionality to style_proportionality, intent_preservation to outcome_intent_preservation. Update all threshold keys to match.
- [x] T003 [US2] Add new deterministic judge process_evaluation_sequence to eval/skill-check/eval.yaml. Python check that verifies the conversation output contains an Activation Test section with both trigger and non-trigger scenarios.
- [x] T004 [US2] Add new deterministic judge style_summary_format to eval/skill-check/eval.yaml. Python check that verifies the summary line matches the pattern "N of M applicable patterns present, X strong, Y improvements suggested".
- [x] T005 [US2] Add new deterministic judge process_step_execution to eval/skill-enhance/eval.yaml. Python check that verifies the conversation output contains a "Steps Executed" section.
- [x] T006 [US2] Update all references to "14 patterns" in both eval configs. In eval/skill-check/eval.yaml: update lines referencing "14 rows", "14 pattern rows", "expected 14", and "14 skill-authoring patterns" (4 occurrences). In eval/skill-enhance/eval.yaml: update references to "14 patterns" (2 occurrences at lines 115 and 128). All should reference 17 patterns.

**Checkpoint**: Both eval.yaml files have all judges prefixed with goal categories, all four categories represented, thresholds matching new names.

---

## Phase 2: User Story 1 - Goal-Category Comparison Report (Priority: P1)

**Goal**: Update compare-runs.sh to group judges by goal category and emit JSON output.

**Independent Test**: Run compare-runs.sh against two summary.yaml files with goal-prefixed judges. Verify grouped output and comparison.json.

### Implementation for User Story 1

- [x] T007 [US1] Add category extraction function to skill/scripts/compare-runs.sh. Extract goal-category prefix by splitting judge name on first underscore. Names without underscore go to "other" with stderr warning.
- [x] T008 [US1] Modify terminal output in skill/scripts/compare-runs.sh to group judges under category headings (Outcome, Process, Style, Efficiency, Other) instead of flat list.
- [x] T009 [US1] Add per-category summary line to skill/scripts/compare-runs.sh terminal and markdown output. Format: "Category summary: Outcome: Improved, Process: Unchanged, Style: Regressed, Efficiency: Unchanged".
- [x] T010 [US1] Update markdown report generation in skill/scripts/compare-runs.sh to group judges by category with category headings in comparison.md.
- [x] T011 [US1] Add JSON output generation to skill/scripts/compare-runs.sh. Write comparison.json to the enhanced run directory with per-judge scores (including category field), per-category aggregates, and overall summary. Warn to stderr on write failure without failing the script.

**Checkpoint**: compare-runs.sh produces grouped terminal output, grouped markdown report, and valid comparison.json.

---

## Phase 3: User Story 3 - Typed Invocation Annotations (Priority: P2)

**Goal**: Add invocation_type field to eval case annotations and support per-type breakdowns in JSON.

**Independent Test**: Verify annotations.yaml files contain invocation_type field. Verify comparison.json includes by_invocation_type section structure.

### Implementation for User Story 3

- [x] T012 [P] [US3] Add invocation_type: explicit to all 5 annotations.yaml files in eval/skill-check/cases/case-*/annotations.yaml.
- [x] T013 [P] [US3] Add invocation_type: explicit to all 5 annotations.yaml files in eval/skill-enhance/cases/case-*/annotations.yaml.
- [x] T014 [US3] Update the dataset.schema section in eval/skill-check/eval.yaml to document the new invocation_type field (values: explicit, implicit, contextual; defaults to explicit if omitted).
- [x] T015 [US3] Update the dataset.schema section in eval/skill-enhance/eval.yaml to document the new invocation_type field.
- [x] T016 [US3] Add by_invocation_type placeholder structure to comparison.json generation in skill/scripts/compare-runs.sh. Include an empty object as placeholder since per-case data is not yet available from the harness summary.yaml.

**Checkpoint**: All annotations have invocation_type, eval.yaml schemas document the field, comparison.json has by_invocation_type structure.

---

## Phase 4: Polish & Cross-Cutting Concerns

**Purpose**: Documentation updates and consistency

- [x] T017 [P] Update skill/skills/measure/SKILL.md to reference the new goal-prefixed judge names where applicable and mention per-category comparison output.
- [x] T018 [P] ~~Update skill/CLAUDE.md to reference 17 patterns~~ Already says "17 skill-authoring patterns". No change needed.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (US2)**: No dependencies, starts immediately. Renames judges and adds new ones.
- **Phase 2 (US1)**: Depends on Phase 1 completion. compare-runs.sh needs goal-prefixed judge names to group by.
- **Phase 3 (US3)**: Independent of Phases 1 and 2. Can run in parallel with Phase 2.
- **Phase 4 (Polish)**: Depends on all prior phases.

### Within Each Phase

- T001 and T002 can run in parallel (different eval.yaml files)
- T003, T004, T005 depend on T001/T002 (add to already-renamed files)
- T007 through T011 are sequential (each builds on prior compare-runs.sh changes)
- T012 and T013 can run in parallel (different case directories)

### Parallel Opportunities

```
Phase 1: T001 ──┐
         T002 ──┤── T003, T004, T005, T006 (sequential on respective files)
                │
Phase 2: T007 → T008 → T009 → T010 → T011
                │
Phase 3: T012 ──┤── T014, T015, T016
         T013 ──┘
                │
Phase 4: T017 ──┐
         T018 ──┘
```

---

## Implementation Strategy

### MVP First (User Story 2 + User Story 1)

1. Complete Phase 1: Rename judges and add new ones in eval.yaml files
2. Complete Phase 2: Update compare-runs.sh for grouped output and JSON
3. **STOP and VALIDATE**: Run compare-runs.sh against existing summary.yaml files
4. This delivers the core value: per-category comparison reports

### Incremental Delivery

1. Phase 1 (US2) -> Eval configs reorganized
2. Phase 2 (US1) -> Comparison reports show category grouping + JSON
3. Phase 3 (US3) -> Annotations enriched with invocation types
4. Phase 4 -> Documentation consistent

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story
- All changes are to existing files, no new directories created
- compare-runs.sh changes are the most complex (T007-T011), test with sample data
- Commit after each task or logical group
