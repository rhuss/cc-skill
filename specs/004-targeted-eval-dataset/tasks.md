# Tasks: Targeted Eval Dataset for Enhancement Coverage

**Input**: Design documents from `/specs/004-targeted-eval-dataset/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- Include exact file paths in descriptions

## Phase 1: Setup

**Purpose**: Configuration and prerequisite changes

- [X] T001 Add `targeted_cases_per_pattern` field to `eval.yaml` under the `dataset` section with default value 1 and a comment explaining its purpose

---

## Phase 2: Foundational (Enhancement Diff Parsing)

**Purpose**: Core parsing logic that both user stories depend on. This logic lives inside the SKILL.md as procedural instructions for the LLM, not as executable code.

**CRITICAL**: US1 and US2 both depend on the ability to parse the "What Changed" table from `/skill:enhance` output. This must be specified clearly before story-specific steps can be added.

- [X] T002 Add a new "Step 4a: Parse Enhancement Diff" section to `skill/skills/measure/SKILL.md` after existing Step 4. This step must instruct the LLM to: (1) extract the "What Changed" markdown table from the `/skill:enhance` conversation output, (2) parse each row to get pattern_name from "Pattern Applied" column and change_description from "What was added/changed" column, (3) also extract the "Status Change" table to confirm which patterns genuinely changed status, (4) store the parsed list as `ENHANCEMENT_DIFF`. Include a fallback: if the table is absent or unparseable, set `ENHANCEMENT_DIFF` to empty and warn that targeted coverage cannot be generated.
- [X] T003 Add a new "Step 4b: Check for Existing Coverage" section to `skill/skills/measure/SKILL.md` after Step 4a. This step must instruct the LLM to: (1) scan all directories in `eval/cases/` for `annotations.yaml` files, (2) for each entry in `ENHANCEMENT_DIFF`, check if any existing annotation has a `targets_pattern` field matching the pattern name OR if any directory name contains the pattern slug (lowercase, spaces to hyphens), (3) remove already-covered patterns from `ENHANCEMENT_DIFF`, (4) store the filtered list as `UNCOVERED_PATTERNS`. If `UNCOVERED_PATTERNS` is empty, skip to Step 5 (re-evaluation) with a note that all enhanced patterns are already covered.

**Checkpoint**: The measure skill can now parse enhancement diffs and identify uncovered patterns. No case generation yet.

---

## Phase 3: User Story 1 - Measure with Targeted Coverage (Priority: P1) MVP

**Goal**: Generate targeted test cases for uncovered enhanced patterns, merge them into the dataset, and run both evals against the combined dataset.

**Independent Test**: Run `/skill:measure path/to/SKILL.md` on a skill where the enhancer adds patterns not covered by the existing dataset. Verify that new test cases appear in `eval/cases/`, both evals run against the combined set, and the comparison report includes scores for targeted cases.

### Implementation for User Story 1

- [X] T004 [US1] Add a new "Step 4c: Generate Targeted Cases" section to `skill/skills/measure/SKILL.md` after Step 4b. This step must instruct the LLM to: (1) read `targeted_cases_per_pattern` from `eval.yaml` (default 1), (2) for each pattern in `UNCOVERED_PATTERNS`, invoke `/eval-dataset` with context explaining which pattern to target and what kind of synthetic SKILL.md to create, (3) each generated case directory must follow the naming convention `case-NNN-targeted-<pattern-slug>/` where NNN is one higher than the current max case number, (4) each `annotations.yaml` must include a `targets_pattern` field with the pattern name, (5) track successfully generated cases as `TARGETED_CASES` and failed patterns as `FAILED_PATTERNS`. Include the fallback: if `/eval-dataset` is not available, skip generation with a warning and set `TARGETED_CASES` to empty.
- [X] T005 [US1] Add a new "Step 4d: Merge Targeted Cases" section to `skill/skills/measure/SKILL.md` after Step 4c. This step must instruct the LLM to: (1) confirm all generated cases are written to `eval/cases/` (they should already be there from Step 4c), (2) verify the total case count (original + targeted) matches expectations, (3) store the count as `TOTAL_CASE_COUNT` for reporting. If `TARGETED_CASES` is empty (nothing generated), skip this step.
- [X] T006 [P] [US1] Modify existing Step 5 (re-evaluation) in `skill/skills/measure/SKILL.md` to note that the eval now runs against the combined dataset (original + targeted cases). Add a sentence clarifying that the eval harness automatically picks up all cases in `eval/cases/` including the newly generated targeted cases.
- [X] T007 [P] [US1] Modify existing Step 7 (summary) in `skill/skills/measure/SKILL.md` to include targeted case reporting. Add to the summary template: (1) number of targeted cases generated, (2) which patterns they target, (3) if any patterns failed to generate, list them with a note. Update the template block to show `**Targeted cases**: N generated for [pattern list]`.
- [X] T008 [P] [US1] Update the "already optimal" early exit in Step 4 of `skill/skills/measure/SKILL.md` to explicitly note that Steps 4a-4d are also skipped (no enhancement diff to parse when nothing changed).
- [X] T009 [P] [US1] Add `ENHANCEMENT_DIFF` and `UNCOVERED_PATTERNS` to the Error Handling table in `skill/skills/measure/SKILL.md`. Add rows for: (1) "Enhancement diff table not found in output" with response to warn and proceed with existing dataset, (2) "eval-dataset skill not available" with response to warn and proceed with existing dataset, (3) "Partial case generation failure" with response to proceed with successful cases and warn about failures.

**Checkpoint**: User Story 1 is complete. The measure skill generates targeted cases, merges them, and runs evals against the combined dataset. Test by running `/skill:measure` on a skill where the enhancer adds uncovered patterns.

---

## Phase 4: User Story 2 - Review Targeted Cases Before Eval (Priority: P2)

**Goal**: Add an interactive review prompt between case generation and eval execution so the author can inspect, approve, reject, or edit targeted cases.

**Independent Test**: Run `/skill:measure` and verify that after targeted cases are generated, the skill pauses to show a summary and waits for user input before proceeding with eval.

### Implementation for User Story 2

- [X] T010 [US2] Add a new "Step 4e: Review Targeted Cases" section to `skill/skills/measure/SKILL.md` between Step 4d (merge) and Step 5 (re-evaluation). This step must instruct the LLM to: (1) display a summary table with columns: #, Case Directory, Targets Pattern, Input Synopsis, (2) if `FAILED_PATTERNS` is non-empty, add warning rows for each failed pattern, (3) prompt the user with "Proceed with eval? (y/n/edit)", (4) handle "y" by continuing to Step 5, (5) handle "n" by deleting all generated targeted case directories and continuing to Step 5 with original dataset only, (6) handle "edit" by telling the user to modify cases on disk and then confirming readiness. Store the user's choice for reporting in Step 7.
- [X] T011 [US2] Update Step 7 (summary) in `skill/skills/measure/SKILL.md` to report the review outcome. Add to the summary template: whether targeted cases were approved, rejected, or edited. If rejected, note that the eval ran against the original dataset only.

**Checkpoint**: User Story 2 is complete. The measure skill now pauses for review before eval. Test by running `/skill:measure` and verifying the review prompt appears with case details.

---

## Phase 5: Polish and Cross-Cutting Concerns

**Purpose**: Final validation and documentation

- [X] T012 [P] Update the `description` field in the YAML frontmatter of `skill/skills/measure/SKILL.md` to mention targeted case generation capability (e.g., add "generates targeted test cases for enhanced patterns" to the description)
- [X] T013 [P] Review `skill/skills/measure/SKILL.md` for internal consistency: verify all step numbers are sequential (Steps 1-7 with sub-steps 4a-4e), all cross-references between steps are correct, and the Error Handling table covers all new error conditions
- [X] T014 Manually test the full workflow: run `/skill:measure` on a real SKILL.md, verify targeted cases are generated, review prompt works, cases merge correctly, comparison report includes targeted case scores. Also verify SC-003: time the targeted case generation step and confirm it completes within 30 seconds

---

## Dependencies and Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies, can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 completion. BLOCKS all user stories.
- **User Story 1 (Phase 3)**: Depends on Phase 2 (needs diff parsing and coverage checking)
- **User Story 2 (Phase 4)**: Depends on Phase 3 (review step sits between generation and eval, needs T004-T005 to exist)
- **Polish (Phase 5)**: Depends on Phases 3 and 4

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational phase. No dependency on US2.
- **User Story 2 (P2)**: Depends on US1 completion (the review step is inserted into the workflow that US1 creates). Cannot be implemented independently.

### Within Each User Story

- T004 before T005 (generation before merge)
- T005 before T006 (merge before eval modification)
- T006 and T007 can be done in parallel [P] (different sections of SKILL.md)
- T008 and T009 can be done in parallel [P] (different sections of SKILL.md)

### Parallel Opportunities

- T001 can run in parallel with any Phase 2 task (different files)
- T006 and T007 can run in parallel (modify different sections)
- T008 and T009 can run in parallel (modify different sections)
- T012 and T013 can run in parallel (different concerns)

---

## Parallel Example: User Story 1

```text
# Sequential chain (must be in order):
T002 → T003 → T004 → T005

# After T005, these can run in parallel:
Task T006: "Modify Step 5 re-evaluation note"
Task T007: "Modify Step 7 summary template"

# These can also run in parallel (after T007):
Task T008: "Update already-optimal exit"
Task T009: "Add error handling rows"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Add eval.yaml config field
2. Complete Phase 2: Enhancement diff parsing and coverage checking
3. Complete Phase 3: Targeted case generation, merging, eval, reporting
4. **STOP and VALIDATE**: Run `/skill:measure` on a test skill and verify targeted cases appear
5. This is a usable feature even without the review prompt (US2)

### Incremental Delivery

1. Setup + Foundational -> Diff parsing works
2. Add User Story 1 -> Full targeted coverage workflow (MVP)
3. Add User Story 2 -> Interactive review before eval
4. Polish -> Description update, consistency check, manual testing

---

## Notes

- All tasks modify a single file (`skill/skills/measure/SKILL.md`) except T001 (`eval.yaml`) and T012 (frontmatter update in the same file)
- Since most tasks edit the same file, true parallelism is limited to tasks that modify clearly different sections
- Tasks T002-T011 are all SKILL.md modifications: they add or modify procedural instructions for the LLM, not executable code
- The skill relies on `/eval-dataset` from the agent-eval-harness plugin for actual case generation; the skill only orchestrates the invocation
