# Tasks: Measure-Enhance-Measure Workflow Documentation

**Input**: Design documents from `specs/002-measure-enhance-docs/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Prepare the README structure for the new section

- [ ] T001 Read current README.md and identify insertion point after "How the Enhancer Works" section in README.md

---

## Phase 2: User Story 1 - Learn the Workflow (Priority: P1)

**Goal**: Add the "Measuring Skill Improvement" section with prerequisites and 6-step workflow

**Independent Test**: Reading the section delivers a clear, numbered workflow a user can follow

### Implementation for User Story 1

- [ ] T002 [US1] Add "Measuring Skill Improvement" heading and prerequisites paragraph to README.md
- [ ] T003 [US1] Write the 6-step workflow list with descriptions of each step and which plugin provides it in README.md

**Checkpoint**: A user can read and understand the workflow steps

---

## Phase 3: User Story 2 - Follow a Concrete Walkthrough (Priority: P2)

**Goal**: Add a walkthrough subsection showing the full loop on a realistic skill with sample output

**Independent Test**: Each of the 6 steps has a command invocation and representative output

### Implementation for User Story 2

- [ ] T004 [US2] Write the walkthrough introduction and describe the example skill (a hypothetical code-review skill with weak patterns) in README.md
- [ ] T005 [US2] Write Steps 1-3 of the walkthrough (eval-analyze, eval-dataset, eval-run baseline) with sample commands and representative output in README.md
- [ ] T006 [US2] Write Step 4 of the walkthrough (skill:enhance) with sample command and representative output showing patterns improved in README.md
- [ ] T007 [US2] Write Steps 5-6 of the walkthrough (eval-run enhanced, compare results) with sample commands and before/after score comparison in README.md

**Checkpoint**: The walkthrough shows all 6 steps with realistic commands and output

---

## Phase 4: User Story 3 - Judge Guidance (Priority: P3)

**Goal**: Add guidance on which judges to use for measuring skill quality

**Independent Test**: Section recommends at least 3 judge categories with explanations

### Implementation for User Story 3

- [ ] T008 [US3] Write "Choosing Judges" subsection recommending structural, behavioral, and improvement delta judge categories in README.md

**Checkpoint**: Users can select appropriate judges for their skill evaluation

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Edge cases, final review, and consistency

- [ ] T009 Write "Tips" subsection covering edge cases (already-optimal skills, score decreases) in README.md
- [ ] T010 Review full new section for consistency with existing README tone and heading hierarchy in README.md
- [ ] T011 Update brainstorm/01-skill-eval.md status from "active" to "spec-created" with spec path reference

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies, starts immediately
- **User Story 1 (Phase 2)**: Depends on T001 (insertion point identified)
- **User Story 2 (Phase 3)**: Depends on T003 (workflow section exists to reference)
- **User Story 3 (Phase 4)**: Depends on T003 (workflow context needed)
- **Polish (Phase 5)**: Depends on all user stories complete

### User Story Dependencies

- **User Story 1 (P1)**: Independent after setup
- **User Story 2 (P2)**: Depends on US1 (walkthrough references the workflow steps)
- **User Story 3 (P3)**: Can run in parallel with US2 after US1 is complete

### Parallel Opportunities

- T004-T007 are sequential (walkthrough steps build on each other)
- T008 [US3] can run in parallel with T004-T007 [US2] since they are in separate subsections
- T009-T011 are sequential (polish requires all content present)

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete T001 (setup)
2. Complete T002-T003 (workflow section)
3. **STOP and VALIDATE**: The 6-step workflow is readable and complete
4. This alone delivers value: users can follow the workflow

### Incremental Delivery

1. Add workflow section (US1) - users learn the steps
2. Add walkthrough (US2) - users see it in practice
3. Add judge guidance (US3) - users pick the right judges
4. Polish - edge cases covered, consistency verified

---

## Notes

- All tasks modify a single file: README.md
- No code, tests, or eval configs are created (FR-007)
- Walkthrough uses a hypothetical code-review skill (research decision R2)
- Sample outputs are simplified/representative, not verbatim (research decision R4)
- Total tasks: 11
- Tasks per user story: US1=2, US2=4, US3=1
