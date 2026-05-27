# Tasks: Measure-Enhance-Measure Automation

**Input**: Design documents from `specs/003-eval-automation/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Create directories and foundational structure

- [ ] T001 Create directory structure: `skill/skills/measure/` and `skill/scripts/` directories
- [ ] T002 Update `skill/.claude-plugin/plugin.json` to register the new `skill:measure` skill if needed

---

## Phase 2: User Story 2 - Compare Any Two Eval Runs (Priority: P2, built first as foundation)

**Goal**: Provide a standalone comparison script that computes deltas between two eval runs

**Independent Test**: Run `skill/scripts/compare-runs.sh <run-dir-1> <run-dir-2>` with two eval run directories containing summary.yaml files. Verify terminal table and markdown report output.

**Why P2 before P1**: The comparison script is a dependency of skill:measure (US1 calls it). Building it first enables US1 to invoke it.

### Implementation for User Story 2

- [ ] T003 [US2] Write `skill/scripts/compare-runs.sh` with argument parsing, input validation (check both dirs exist, both have summary.yaml), and error handling (FR-006, FR-010, FR-012)
- [ ] T004 [US2] Add judge extraction logic to `skill/scripts/compare-runs.sh` that reads `summary.yaml` from both directories using `yq`, builds union set of judge names, and reads `pass_rate` (boolean) or `mean` (numeric) per judge (FR-007, FR-011)
- [ ] T005 [US2] Add terminal table output to `skill/scripts/compare-runs.sh` that prints per-judge baseline score, enhanced score, delta, and directional indicator to stdout (FR-008)
- [ ] T006 [US2] Add markdown report generation to `skill/scripts/compare-runs.sh` that writes a detailed comparison report to `<run-dir-2>/comparison.md` with summary counts (improved/regressed/unchanged) and per-judge details (FR-009)
- [ ] T007 [US2] Make `skill/scripts/compare-runs.sh` executable (`chmod +x`)

**Checkpoint**: The comparison script works standalone with any two eval run directories

---

## Phase 3: User Story 1 - Run the Full Enhance Loop (Priority: P1)

**Goal**: Provide a skill that orchestrates baseline-enhance-reeval in a single command

**Independent Test**: Run `/skill:measure path/to/SKILL.md` on a skill with eval.yaml and dataset configured. Verify it runs baseline eval, enhances, re-evals, and presents comparison.

### Implementation for User Story 1

- [ ] T008 [US1] Write `skill/skills/measure/SKILL.md` with frontmatter (name, description, activation triggers, exclusions) following the existing checker/enhancer pattern
- [ ] T009 [US1] Add prerequisite check to `skill/skills/measure/SKILL.md` that detects whether eval.yaml exists for the target skill and directs user to `/eval-analyze` if missing (FR-004)
- [ ] T010 [US1] Add Step 1 (baseline) to `skill/skills/measure/SKILL.md`: invoke `/eval-run` on the target skill's eval config and capture the run directory path from the conversation output (FR-002, FR-014)
- [ ] T011 [US1] Add Step 2 (enhance) to `skill/skills/measure/SKILL.md`: invoke `/skill:enhance` on the target SKILL.md and detect the "already optimal" signal to skip re-evaluation (FR-002, FR-005)
- [ ] T012 [US1] Add Step 3 (re-eval) to `skill/skills/measure/SKILL.md`: invoke `/eval-run` again and capture the second run directory path (FR-002, FR-014)
- [ ] T013 [US1] Add Step 4 (compare) to `skill/skills/measure/SKILL.md`: call `scripts/compare-runs.sh` via Bash with both run directory paths and present the delta report (FR-003, FR-013)
- [ ] T014 [US1] Add error handling to `skill/skills/measure/SKILL.md` for interrupted loops (report what completed and what remains)

**Checkpoint**: The full measure-enhance-measure loop works end-to-end in a single `/skill:measure` invocation

---

## Phase 4: User Story 3 - Review the Comparison Report (Priority: P3)

**Goal**: Ensure the comparison report is clear, actionable, and highlights regressions

**Independent Test**: Read a generated comparison.md and verify it contains summary counts, per-judge deltas with directional indicators, and clear regression highlighting.

### Implementation for User Story 3

- [ ] T015 [US3] Review and refine the markdown report template in `skill/scripts/compare-runs.sh` to ensure it includes a summary section with improved/regressed/unchanged counts, per-judge detail table with directional indicators, and clear regression highlighting

**Checkpoint**: The comparison report is readable and regressions are impossible to miss

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, consistency, and integration

- [ ] T016 Run `/skill:check skill/skills/measure/SKILL.md` to evaluate the new skill against the 14 authoring patterns
- [ ] T017 Apply any improvements suggested by skill:check to `skill/skills/measure/SKILL.md`
- [ ] T018 Update `brainstorm/03-eval-automation.md` status from "active" to "spec-created" with spec path reference

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies, starts immediately
- **User Story 2 (Phase 2)**: Depends on T001 (directory exists)
- **User Story 1 (Phase 3)**: Depends on T007 (compare script complete and executable)
- **User Story 3 (Phase 4)**: Depends on T006 (report generation implemented)
- **Polish (Phase 5)**: Depends on all user stories complete

### User Story Dependencies

- **User Story 2 (P2)**: Independent after setup. Built first because US1 depends on it.
- **User Story 1 (P1)**: Depends on US2 (calls compare-runs.sh)
- **User Story 3 (P3)**: Depends on US2 (reviews the report format from compare-runs.sh)

### Within Each User Story

- US2: T003 (scaffold) then T004 (logic) then T005-T006 [P] (output formats) then T007 (chmod)
- US1: T008 (scaffold) then T009-T014 sequential (each step builds on the previous)
- US3: T015 standalone (refinement of existing output)

### Parallel Opportunities

- T005 and T006 can run in parallel (terminal vs markdown output, same script but different functions)
- T016 and T018 can run in parallel (independent polish tasks)

---

## Implementation Strategy

### MVP First (User Story 2 Only)

1. Complete T001-T002 (setup)
2. Complete T003-T007 (comparison script)
3. **STOP and VALIDATE**: Test compare-runs.sh with two real eval run directories
4. This alone delivers value: users can compare any two runs

### Incremental Delivery

1. Add comparison script (US2): standalone delta reporting
2. Add skill:measure (US1): full orchestrated loop
3. Refine report (US3): polish the output format
4. Quality check: run skill:check on the new skill

---

## Notes

- US2 is built before US1 despite lower priority because US1 depends on it
- Two new files: `skill/skills/measure/SKILL.md` and `skill/scripts/compare-runs.sh`
- No nested claude -p sessions (FR-013): skill:measure invokes skills within the same session
- compare-runs.sh uses yq for YAML parsing (research decision R3)
- Total tasks: 18
- Tasks per user story: US1=7, US2=5, US3=1
