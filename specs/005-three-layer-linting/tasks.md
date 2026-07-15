# Tasks: Three-Layer Skill Linting

**Input**: Design documents from `specs/005-three-layer-linting/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Foundational (Knowledge Base - US5)

**Purpose**: Update the knowledge base that both checker and enhancer depend on. This MUST complete before any checker or enhancer changes.

**Goal**: Expand skill-authoring-patterns.md from 14 to 17 patterns with enriched detection signals on existing patterns.

**Independent Test**: Read the knowledge file and verify 17 pattern entries with complete definitions (detection signals, quality criteria, improvement guidance).

- [x] T001 [US5] Add Pattern 15 (Process over Prose) to skill/knowledge/skill-authoring-patterns.md with applicability, detection signals, quality criteria (strong/present), and improvement guidance following the existing pattern format
- [x] T002 [US5] Add Pattern 16 (Anticipate the Excuse) to skill/knowledge/skill-authoring-patterns.md with applicability, detection signals, quality criteria (strong/present), and improvement guidance following the existing pattern format
- [x] T003 [US5] Add Pattern 17 (Stay in Scope) to skill/knowledge/skill-authoring-patterns.md with applicability, detection signals, quality criteria (strong/present), and improvement guidance following the existing pattern format
- [x] T004 [US5] Enrich Pattern 1 (Activation Metadata) in skill/knowledge/skill-authoring-patterns.md with character budget check signals (1024 Agent Skills, 1536 Claude Code description+when_to_use) and routing rule vs. summary distinction
- [x] T005 [US5] Enrich Pattern 3 (Context Budget) in skill/knowledge/skill-authoring-patterns.md with "omit what the model knows" detection signal from agentskills.io
- [x] T006 [US5] Enrich Pattern 5 (Control Tuning) in skill/knowledge/skill-authoring-patterns.md with "defaults not menus" and "match specificity to fragility" detection signals
- [x] T007 [US5] Enrich Pattern 6 (Explain-the-Why) in skill/knowledge/skill-authoring-patterns.md with "narrow imperative for fragile steps" signal (when NOT to explain)
- [x] T008 [US5] Enrich Pattern 13 (Utility Bundle) in skill/knowledge/skill-authoring-patterns.md with "detect deterministic steps written as LLM prose" signal

**Checkpoint**: Knowledge base has 17 patterns with enriched signals. Checker and enhancer changes can now begin.

---

## Phase 2: Checker - Layer 1 Deterministic Validation (US1)

**Goal**: Add a "Layer 1: Schema Validation" section that runs deterministic pass/fail checks before pattern evaluation.

**Independent Test**: Run `/skill:check` against a SKILL.md with missing frontmatter and verify Layer 1 failures appear before pattern evaluation.

- [x] T009 [US1] Add argument parsing for `--deep` flag in Step 1 of skill/skills/checker/SKILL.md, extracting both file path and optional flag from the argument string
- [x] T010 [US1] Add Layer 1 Schema Validation step (new Step 2.5 between current Step 2 and Step 3) in skill/skills/checker/SKILL.md with deterministic checks: frontmatter presence/validity, required fields (name, description), description character count vs. 1024/1536 limits, known field validation (name, description, argument-hint, user-invocable, disable-model-invocation, allowed-tools), body line count vs. 500 threshold, token budget estimate (word count * 1.3) vs. 5000 threshold
- [x] T011 [US1] Add Layer 1 output format instructions in skill/skills/checker/SKILL.md specifying the "## Layer 1: Schema Validation" heading with pass/fail/warn list and remediation hints for each failed check

**Checkpoint**: Layer 1 deterministic validation runs on every `/skill:check` invocation.

---

## Phase 3: Checker - Expanded Pattern Assessment (US2)

**Goal**: Expand Layer 2 from 14 to 17 patterns with principle enrichments and updated summary line.

**Independent Test**: Run `/skill:check` against a skill with workflow steps, rebuttal tables, and scope-bounding instructions and verify 17 patterns are evaluated.

- [x] T012 [US2] Update all "14 patterns" references to "17 patterns" in skill/skills/checker/SKILL.md (description frontmatter, Step 2 knowledge loading, Step 3 evaluation instructions)
- [x] T013 [US2] Add lifecycle signals subsection instructions after the pattern table in skill/skills/checker/SKILL.md (Layer 2 informational section: check for last-tested date, owner, version metadata with observability disclaimer)
- [x] T014 [US2] Update the summary line format in skill/skills/checker/SKILL.md to use: "Layer 1: X/Y passed | A of B patterns present, C strong | [Deep: verdict]"
- [x] T015 [US2] Update the output format instructions in skill/skills/checker/SKILL.md to present three clearly separated sections: "## Layer 1: Schema Validation", "## Layer 2: Pattern & Principle Assessment", and "## Layer 3: Substance Review (--deep)" with Layer 3 only appearing when --deep is used

**Checkpoint**: Layer 2 evaluates 17 patterns with enriched signals and lifecycle checks.

---

## Phase 4: Checker - Substance Review (US3)

**Goal**: Add optional Layer 3 substance review gated on `--deep` flag.

**Independent Test**: Run `/skill:check --deep` against a skill and verify all three layers appear; run without `--deep` and verify only Layers 1 and 2 appear.

- [x] T016 [US3] Add Layer 3 Substance Review step in skill/skills/checker/SKILL.md (new step after pattern evaluation), gated on `--deep` flag, producing narrative assessment with labeled subsections: Purpose Sensibility, Harmful Output Risk, Example Realism, Workflow Completeness, and an Overall Verdict line with pass/concern/fail rating
- [x] T017 [US3] Update the YAML frontmatter description in skill/skills/checker/SKILL.md to mention three-layer model and `--deep` flag for substance review

**Checkpoint**: Full three-layer checker is operational with optional `--deep` for Layer 3.

---

## Phase 5: Enhancer Updates (US4)

**Goal**: Expand the enhancer to improve skills against all 17 patterns including the three new enhancement strategies.

**Independent Test**: Run `/skill:enhance` against a skill that is purely descriptive prose and verify it gets restructured into a workflow with actionable steps.

- [x] T018 [US4] Update all "14 patterns" references to "17 patterns" in skill/skills/enhancer/SKILL.md (description frontmatter, Step 2 knowledge loading, Step 3 baseline evaluation, Step 4 enhancement decisions)
- [x] T019 [US4] Add enhancement strategy for Pattern 15 (Process over Prose) in skill/skills/enhancer/SKILL.md Step 4: restructure descriptive prose into numbered workflow steps with entry/exit conditions
- [x] T020 [US4] Add enhancement strategy for Pattern 16 (Anticipate the Excuse) in skill/skills/enhancer/SKILL.md Step 4: identify MUST/NEVER rules and generate rebuttal tables with 2-3 rationalizations each
- [x] T021 [US4] Add enhancement strategy for Pattern 17 (Stay in Scope) in skill/skills/enhancer/SKILL.md Step 4: add scope-bounding section with explicit positive and negative constraints
- [x] T022 [US4] Update the YAML frontmatter description in skill/skills/enhancer/SKILL.md to reference 17 patterns instead of 14

**Checkpoint**: Enhancer can improve skills against all 17 patterns.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Update supporting files that reference pattern counts.

- [x] T023 [P] Update version from 1.1.0 to 1.2.0 and description to mention 17 patterns in skill/.claude-plugin/plugin.json
- [x] T024 [P] Update "14 skill-authoring patterns" to "17 skill-authoring patterns" in skill/CLAUDE.md Knowledge Loading section
- [x] T025 [P] Update any "14 patterns" references to "17 patterns" in skill/skills/measure/SKILL.md

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Knowledge Base)**: No dependencies - start here. BLOCKS all other phases.
- **Phase 2 (Checker Layer 1)**: Depends on Phase 1. Can run in parallel with Phases 3-5 since Layer 1 checks are independent of pattern content.
- **Phase 3 (Checker Layer 2)**: Depends on Phase 1 (needs 17 patterns in knowledge file).
- **Phase 4 (Checker Layer 3)**: Depends on Phase 2 and 3 (modifies same file, needs prior checker changes in place).
- **Phase 5 (Enhancer)**: Depends on Phase 1. Can run in parallel with Phases 2-4 (different file).
- **Phase 6 (Polish)**: Depends on all prior phases.

### User Story Dependencies

- **US5 (Knowledge Base)**: Foundational. No dependencies on other stories. BLOCKS US1, US2, US3, US4.
- **US1 (Layer 1)**: Depends on US5. Independent of US2, US3, US4.
- **US2 (Expanded Patterns)**: Depends on US5. Modifies same file as US1/US3 so should follow US1.
- **US3 (Substance Review)**: Depends on US5. Modifies same file as US1/US2 so should follow US2.
- **US4 (Enhancer)**: Depends on US5. Independent of US1/US2/US3 (different file).

### Parallel Opportunities

- T001, T002, T003 can run in parallel (different pattern sections appended to same file, but sequentially safer)
- T004-T008 can run in parallel (different pattern sections in same file, but sequentially safer)
- T023, T024, T025 can all run in parallel (different files)
- US4 (enhancer, Phase 5) can run in parallel with US1+US2+US3 (checker, Phases 2-4) since they edit different files

---

## Implementation Strategy

### MVP First (Knowledge Base + Checker Layer 2)

1. Complete Phase 1: Knowledge Base (US5)
2. Complete Phase 3: Checker Expanded Patterns (US2)
3. **STOP and VALIDATE**: Run `/skill:check` and verify 17 patterns evaluated
4. This gives the core value: expanded pattern assessment

### Incremental Delivery

1. Knowledge Base (US5) → Foundation ready
2. Checker Layer 1 (US1) → Deterministic validation added
3. Checker Layer 2 expansion (US2) → 17 patterns evaluated
4. Checker Layer 3 (US3) → Deep substance review available
5. Enhancer (US4) → Can improve against all 17 patterns
6. Polish → Version bump, docs updated

---

## Notes

- All changes are to Markdown files (no compilation, no build step)
- Testing is manual: run `/skill:check` and `/skill:enhance` against real SKILL.md files
- The knowledge file is the single source of truth for pattern definitions
- Checker and enhancer both dynamically load the knowledge file at invocation time
- US1/US2/US3 all modify skill/skills/checker/SKILL.md, so they must be sequential
- US4 modifies skill/skills/enhancer/SKILL.md, so it can run in parallel with checker changes
