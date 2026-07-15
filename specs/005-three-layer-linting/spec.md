# Feature Specification: Three-Layer Skill Linting

**Feature Branch**: `005-three-layer-linting`
**Created**: 2026-07-14
**Status**: Draft
**Input**: Adopt Bilgin Ibryam's three-layer linting model for skill:check, expanding from 14 to 17 patterns, adding deterministic validation (Layer 1) and optional substance review (Layer 3).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Deterministic Validation on Every Check (Priority: P1)

A skill author runs `/skill:check path/to/SKILL.md` and sees a new "Schema Validation" section at the top of the output before the familiar pattern table. This section shows pass/fail results for structural checks: frontmatter presence, required fields, description length against platform limits, body line count, and estimated token budget. Failures are prominently flagged in the summary to signal the author should fix structural issues, but Layer 2 always runs regardless of Layer 1 results.

**Why this priority**: Deterministic checks are cheap, fast, and catch the most basic errors. They prevent wasted effort on pattern-level review when the skill has structural problems. This is the foundation that makes the other layers reliable.

**Independent Test**: Can be fully tested by running `/skill:check` against a skill with missing frontmatter or an oversized description and verifying that Layer 1 failures appear before any pattern evaluation.

**Acceptance Scenarios**:

1. **Given** a SKILL.md with no YAML frontmatter, **When** the user runs `/skill:check`, **Then** Layer 1 reports "FAIL: No YAML frontmatter found" and Layer 2 still runs but the summary notes the Layer 1 failure.
2. **Given** a SKILL.md with a description longer than 1024 characters, **When** the user runs `/skill:check`, **Then** Layer 1 reports a warning with the character count and the applicable platform limit.
3. **Given** a SKILL.md with a body exceeding 500 lines, **When** the user runs `/skill:check`, **Then** Layer 1 reports a warning with the line count.
4. **Given** a well-formed SKILL.md under all thresholds, **When** the user runs `/skill:check`, **Then** Layer 1 shows all checks as PASS and the output proceeds to Layer 2.

---

### User Story 2 - Expanded Pattern Assessment with Three New Patterns (Priority: P1)

A skill author runs `/skill:check` and sees 17 patterns evaluated instead of 14. The three new patterns (Process over Prose, Anticipate the Excuse, Stay in Scope) appear in the pattern table with the same two-tier quality ratings (strong/present) as existing patterns. Existing patterns also show enriched detection signals where principle-level guidance applies (character budget checks in Activation Metadata, "omit what the model knows" in Context Budget, etc.).

**Why this priority**: The expanded pattern set is the core value proposition. Without it, the tool remains a 14-pattern checker that misses important skill quality dimensions.

**Independent Test**: Can be tested by running `/skill:check` against a skill that has workflow steps (should score on Process over Prose), rebuttal tables (should score on Anticipate the Excuse), and scope-bounding instructions (should score on Stay in Scope).

**Acceptance Scenarios**:

1. **Given** a SKILL.md with clear numbered workflow steps, **When** the user runs `/skill:check`, **Then** Pattern 15 (Process over Prose) is rated "present" or "strong".
2. **Given** a SKILL.md that is entirely descriptive prose with no actionable steps, **When** the user runs `/skill:check`, **Then** Pattern 15 is rated "absent" with improvement guidance.
3. **Given** a SKILL.md with a rebuttal table near a non-negotiable rule, **When** the user runs `/skill:check`, **Then** Pattern 16 (Anticipate the Excuse) is rated "present" or "strong".
4. **Given** a SKILL.md with explicit scope-bounding instructions ("Only modify files in X", "Do NOT touch Y"), **When** the user runs `/skill:check`, **Then** Pattern 17 (Stay in Scope) is rated "present" or "strong".
5. **Given** a SKILL.md with an Activation Metadata description exceeding 1024 characters, **When** the user runs `/skill:check`, **Then** Pattern 1 evaluation notes the character budget issue as part of its enriched assessment.

---

### User Story 3 - Optional Substance Review (Priority: P2)

A skill author runs `/skill:check path/to/SKILL.md --deep` and gets a narrative substance review after Layers 1 and 2. This review answers senior-engineer questions: Does the skill do something sensible? Could instructions produce harmful output if followed literally? Are examples realistic? Does the workflow have dead ends? The review produces a structured verdict, not a table.

**Why this priority**: Substance review catches qualitative problems that structural and pattern checks miss, but it is expensive (requires LLM inference) and non-deterministic. Making it optional keeps the default check fast while giving authors a thorough option for high-stakes skills.

**Independent Test**: Can be tested by running `/skill:check --deep` against a skill with an unreachable workflow branch and verifying the substance review identifies it.

**Acceptance Scenarios**:

1. **Given** a SKILL.md, **When** the user runs `/skill:check --deep`, **Then** the output includes all three layers: Schema Validation, Pattern Assessment, and Substance Review.
2. **Given** a SKILL.md, **When** the user runs `/skill:check` without `--deep`, **Then** only Layers 1 and 2 appear in the output.
3. **Given** a SKILL.md with a workflow that has an unreachable branch (e.g., an error handler that can never trigger), **When** the user runs `/skill:check --deep`, **Then** the substance review identifies the dead-end branch.
4. **Given** a SKILL.md with contrived examples that do not match the stated purpose, **When** the user runs `/skill:check --deep`, **Then** the substance review flags the examples as unrealistic.

---

### User Story 4 - Enhancer Works with 17 Patterns (Priority: P2)

A skill author runs `/skill:enhance path/to/SKILL.md` and the enhancer can improve the skill against all 17 patterns, not just 14. Specifically, the enhancer can restructure prose into workflow steps (for Process over Prose), generate rebuttal tables near hard rules (for Anticipate the Excuse), and add scope-bounding instructions (for Stay in Scope).

**Why this priority**: The enhancer must keep pace with the checker. If the checker identifies absent patterns that the enhancer cannot address, authors are left without actionable improvement paths.

**Independent Test**: Can be tested by running `/skill:enhance` against a skill that is purely descriptive prose and verifying it gets restructured into a workflow with actionable steps.

**Acceptance Scenarios**:

1. **Given** a SKILL.md rated "absent" on Process over Prose by the checker, **When** the user runs `/skill:enhance`, **Then** the enhanced skill contains numbered workflow steps and the checker subsequently rates it "present" or better.
2. **Given** a SKILL.md with hard rules but no rebuttal tables, **When** the user runs `/skill:enhance`, **Then** the enhanced skill includes rebuttal tables near the rules.
3. **Given** a SKILL.md with no scope-bounding instructions, **When** the user runs `/skill:enhance`, **Then** the enhanced skill includes explicit scope constraints.

---

### User Story 5 - Updated Knowledge Base (Priority: P1)

The knowledge file `skill-authoring-patterns.md` is expanded from 14 to 17 patterns. Each new pattern follows the same format as existing ones: applicability, description, detection signals, quality criteria (strong/present), and improvement guidance. Existing patterns that receive principle-level enrichments have updated detection signals and quality criteria.

**Why this priority**: The knowledge base is the single source of truth for both checker and enhancer. Without updating it, neither tool can evaluate or improve against the new patterns.

**Independent Test**: Can be tested by reading the knowledge file and verifying it contains 17 pattern entries with complete definitions.

**Acceptance Scenarios**:

1. **Given** the updated knowledge file, **When** a reader counts pattern entries, **Then** there are exactly 17 patterns.
2. **Given** Pattern 15 (Process over Prose), **When** a reader checks its definition, **Then** it includes detection signals, quality criteria with strong/present tiers, and improvement guidance.
3. **Given** Pattern 1 (Activation Metadata), **When** a reader checks its definition, **Then** it includes enriched detection signals for character budget limits (1024/1536).
4. **Given** Pattern 3 (Context Budget), **When** a reader checks its definition, **Then** it includes the "omit what the model knows" signal.

---

### Edge Cases

- What happens when a SKILL.md has valid frontmatter but the body is empty? Layer 1 should pass structural checks; Layer 2 should rate most patterns as absent.
- How does the checker handle a SKILL.md with frontmatter fields that are not in the known set? Layer 1 should emit a warning for unknown fields but not a hard failure.
- What happens if `--deep` is used on a very short skill (under 10 lines)? The substance review should still run but note that the skill may be too brief for meaningful assessment.
- How does the checker handle a SKILL.md without a `description` field? Layer 1 should report this as a FAIL for the required-fields check.
- What happens when a skill has lifecycle metadata (last-tested, owner) but the values are clearly stale? The lifecycle check should note the presence but flag staleness as a limited observation.

## Clarifications

### Session 2026-07-14

- Q: Does Layer 2 run when Layer 1 has failures, or are Layer 1 failures hard blockers? → A: Layer 2 always runs regardless of Layer 1 results. Layer 1 failures are prominently flagged in the summary but do not block subsequent layers. The term "hard blocker" in the user story refers to the author's action (they should fix structural issues), not to the tool's behavior (the tool still runs all layers).
- Q: What format should the summary line use to reflect the three-layer model? → A: `Layer 1: X/Y passed | A of B patterns present, C strong | [Deep: verdict]` combining all active layers in one line. The Deep segment only appears when `--deep` is used.
- Q: Which layer do lifecycle signal checks (FR-015) belong to? → A: Layer 2, as an informational subsection after the pattern table. Lifecycle checks involve judgment (staleness assessment) rather than pure pass/fail, making them a better fit for the best-practice layer than the deterministic layer.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The checker MUST produce a "Layer 1: Schema Validation" section before the pattern table, containing pass/fail results for each deterministic check. Each failed check MUST include a brief remediation hint (e.g., "FAIL: No YAML frontmatter found. Add `---` delimiters with `name` and `description` fields at the top of the file.").
- **FR-002**: Layer 1 MUST check for YAML frontmatter presence and validity (parseable YAML between `---` delimiters).
- **FR-003**: Layer 1 MUST check for required fields (`name`, `description`) in the frontmatter.
- **FR-004**: Layer 1 MUST check description character count against known platform limits (1024 for Agent Skills spec, 1536 for Claude Code description + when_to_use combined) and report warnings when exceeded.
- **FR-005**: Layer 1 MUST check body line count and emit a warning when the body exceeds 500 lines.
- **FR-006**: Layer 1 MUST estimate token budget for the body and emit a warning when the body exceeds an estimated 5000 tokens.
- **FR-007**: Layer 1 MUST validate frontmatter fields against the known field set (`name`, `description`, `argument-hint`, `user-invocable`, `disable-model-invocation`, `allowed-tools`) and warn on unknown fields. This list reflects current Claude Code SKILL.md conventions and should be updated if the platform adds new fields.
- **FR-008**: The checker MUST evaluate 17 patterns in Layer 2 instead of 14, adding Process over Prose, Anticipate the Excuse, and Stay in Scope.
- **FR-009**: Each new pattern MUST use the same two-tier quality rating (strong/present/absent) as existing patterns.
- **FR-010**: Existing patterns MUST be enriched with principle-level detection signals where applicable:
  - **Activation Metadata**: Add detection for description character count against platform limits (1024 for Agent Skills, 1536 for Claude Code combined description + when_to_use).
  - **Context Budget**: Add detection for instructions that repeat knowledge the model already has, rather than omitting it and focusing on project-specific context.
  - **Control Tuning**: Add detection for "menu-style" options that offer the LLM choices where a sensible default should be enforced instead.
  - **Explain-the-Why**: Add detection for fragile steps that use broad imperatives ("handle errors appropriately") instead of narrow, specific instructions with rationale.
  - **Utility Bundle**: Add detection for deterministic operations (parsing, counting, formatting) written as LLM prose instructions instead of being delegated to scripts.
- **FR-011**: The checker MUST support a `--deep` flag that enables Layer 3 (Substance Review).
- **FR-012**: Layer 3 MUST produce a narrative assessment answering at least four senior-engineer questions: purpose sensibility, harmful output potential, example realism, and workflow completeness.
- **FR-013**: Layer 3 MUST produce a structured verdict (not a table) with an overall assessment. The output MUST use a narrative format with labeled subsections for each senior-engineer question (e.g., "Purpose Sensibility:", "Harmful Output Risk:", "Example Realism:", "Workflow Completeness:"), each containing 1-3 sentences, followed by an "Overall Verdict:" line with a one-sentence summary and a pass/concern/fail rating.
- **FR-014**: When `--deep` is not specified, only Layers 1 and 2 MUST appear in the output.
- **FR-015**: The checker MUST include limited lifecycle signal checks in Layer 2, presented as an informational subsection after the pattern table: presence of last-tested date, owner, and version metadata, with a disclaimer that runtime behavior cannot be observed.
- **FR-016**: The knowledge base (`skill-authoring-patterns.md`) MUST be updated to contain all 17 patterns with complete definitions.
- **FR-017**: The enhancer MUST evaluate and improve skills against all 17 patterns.
- **FR-018**: The enhancer MUST be able to restructure descriptive prose into workflow steps (for Process over Prose).
- **FR-019**: The enhancer MUST be able to generate rebuttal tables near hard rules (for Anticipate the Excuse).
- **FR-020**: The enhancer MUST be able to add scope-bounding instructions (for Stay in Scope).
- **FR-021**: The checker summary line MUST use the format: `Layer 1: X/Y passed | A of B patterns present, C strong | [Deep: verdict]`, combining all active layers in one line. The Deep segment only appears when `--deep` is used.
- **FR-022**: The output format MUST present three clearly separated sections: Schema Validation, Pattern & Principle Assessment, and Substance Review (when enabled).

### Key Entities

- **Pattern**: A skill-authoring best practice with detection signals, quality criteria (strong/present/absent), and improvement guidance. 17 total across 7 categories (Discovery, Context Economy, Instruction Calibration, Workflow Control, Executable Code, Meta, Workflow Quality).
- **Layer**: A depth of analysis (deterministic, best-practice, substance) with different cost/value tradeoffs.
- **Deterministic Check**: A binary pass/fail validation that requires no LLM judgment (frontmatter parsing, character counting, field validation).
- **Principle Enrichment**: Additional detection signals added to existing patterns based on the 9 design principles, strengthening the quality criteria.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Running `/skill:check` on any SKILL.md produces output with Layer 1 (Schema Validation) appearing before Layer 2 (Pattern Assessment).
- **SC-002**: The pattern table in Layer 2 shows 17 pattern rows instead of 14.
- **SC-003**: Running `/skill:check --deep` produces all three layers in the output; running without `--deep` produces only two.
- **SC-004**: Running `/skill:enhance` on a skill with absent new patterns (15, 16, 17) produces improvements that the checker subsequently rates as "present" or "strong".
- **SC-005**: The knowledge file contains exactly 17 pattern entries, each with detection signals, quality criteria, and improvement guidance.
- **SC-006**: Layer 1 correctly identifies structural issues (missing frontmatter, oversized descriptions, excessive line counts) in skills that have those problems.

## Out of Scope

- **External tooling for Layer 1**: No shell scripts, YAML parsers, or external validators. All Layer 1 checks are performed by the LLM reading the skill content (see Assumptions).
- **CI/CD integration**: No automated pipeline integration, pre-commit hooks, or batch-checking of multiple skills.
- **Result caching**: No caching of previous check results for comparison or regression detection.
- **Scoring or numeric grades**: The checker produces categorical ratings (strong/present/absent/pass/fail), not numeric scores or percentages.
- **New flags beyond `--deep`**: No `--fix`, `--json`, `--quiet`, or other output mode flags in this feature.

## Assumptions

- The existing 14-pattern evaluation logic in the checker skill remains unchanged in behavior; only three new patterns and enrichment signals are added.
- Layer 1 deterministic checks are performed by the LLM reading and analyzing the skill content, not by external tooling or scripts. The checks are "deterministic" in the sense that they have binary pass/fail criteria, not that they run outside the LLM.
- Token estimation for the 5000-token threshold uses a rough heuristic (word count * 1.3) rather than precise tokenizer output, since the checker runs within the LLM context.
- The `--deep` flag is parsed from the argument string passed to `/skill:check` alongside the file path.
- Platform character limits (1024 for Agent Skills, 1536 for Claude Code) are based on current published specifications and may change.
- The enhancer's existing interaction model (user approval before changes) is preserved; the three new enhancement capabilities follow the same approval flow.
