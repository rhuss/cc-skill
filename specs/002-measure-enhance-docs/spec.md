# Feature Specification: Measure-Enhance-Measure Workflow Documentation

**Feature Branch**: `002-measure-enhance-docs`  
**Created**: 2026-05-26  
**Status**: Draft  
**Input**: User description: "Document the measure-enhance-measure workflow in cc-skill's README showing how to combine agent-eval-harness with skill:enhance to measure skill improvement quantitatively."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Learn the Measure-Enhance-Measure Workflow (Priority: P1)

A skill author has a SKILL.md they want to improve. They have both the cc-skill plugin and the agent-eval-harness plugin installed. They read the README to learn the step-by-step workflow for measuring their skill's quality, enhancing it, and then measuring again to verify improvement.

**Why this priority**: Without understanding the workflow, users cannot combine the two plugins effectively. This is the core value of the documentation.

**Independent Test**: Can be fully tested by reading the README section and following the 6 steps on any SKILL.md file. Delivers a clear, repeatable workflow that a user can follow without prior knowledge of either plugin's internals.

**Acceptance Scenarios**:

1. **Given** a user reading the README, **When** they reach the "Measuring Skill Improvement" section, **Then** they find a numbered 6-step workflow with clear descriptions of what each step does and which plugin provides it.
2. **Given** a user with both plugins installed, **When** they follow the documented steps in order on their own SKILL.md, **Then** they can complete the full measure-enhance-measure cycle without consulting additional documentation.
3. **Given** a user unfamiliar with agent-eval-harness, **When** they read the workflow section, **Then** they understand the role of each eval-harness command (eval-analyze, eval-dataset, eval-run) without needing to read the harness's own documentation first.

---

### User Story 2 - Follow a Concrete Walkthrough (Priority: P2)

A skill author wants to see what the workflow looks like in practice before trying it themselves. They read through a concrete example showing the full loop applied to a real skill, with representative output at each step.

**Why this priority**: Abstract workflow steps are harder to follow than a concrete example. The walkthrough builds confidence and sets expectations for what each step produces.

**Independent Test**: Can be tested by reading the walkthrough section and verifying that each step shows realistic input/output that matches what the eval-harness and skill:enhance actually produce.

**Acceptance Scenarios**:

1. **Given** a user reading the walkthrough, **When** they reach each step, **Then** they see sample command invocations and representative output showing what that step produces.
2. **Given** a user following along with their own skill, **When** they compare their output to the walkthrough, **Then** the format and structure match (even though specific scores and content differ).
3. **Given** a user who completed the walkthrough, **When** they look at the before/after comparison at the end, **Then** they can see how the eval scores changed after enhancement.

---

### User Story 3 - Understand Which Judges to Use (Priority: P3)

A skill author has completed the workflow but wants to know which eval judges are most informative for measuring skill quality. They consult the documentation for guidance on judge selection.

**Why this priority**: The eval-harness supports many judge types. Without guidance, users may pick judges that don't measure skill quality meaningfully. This section prevents wasted eval cycles.

**Independent Test**: Can be tested by reading the judges guidance section and verifying that it recommends specific judge types relevant to skill quality (structural completeness, behavioral correctness, output actionability).

**Acceptance Scenarios**:

1. **Given** a user reading the judges section, **When** they look for guidance, **Then** they find recommended judge categories with explanations of what each measures about skill quality.
2. **Given** a user setting up eval-analyze, **When** they configure judges, **Then** the documentation helps them choose judges appropriate for their skill type.

---

### Edge Cases

- What happens when the user only has one of the two plugins installed? The prerequisites section should state both are required and explain how to install each.
- What happens when skill:enhance reports "already optimal" (all patterns strong)? The workflow should note that if no enhancement is needed, the re-evaluation step will confirm identical scores rather than showing improvement.
- What happens when eval-run scores decrease after enhancement? The documentation should acknowledge this possibility and suggest investigating whether the enhancement changed the skill's behavior in unintended ways.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: README MUST contain a new section titled "Measuring Skill Improvement" documenting the measure-enhance-measure workflow.
- **FR-002**: The workflow section MUST list all 6 steps in order, identifying which plugin provides each step.
- **FR-003**: The workflow section MUST include the prerequisite of having both cc-skill and agent-eval-harness plugins installed.
- **FR-004**: The README MUST include a concrete walkthrough showing the full workflow applied to a real skill, with representative command invocations and sample output for each step.
- **FR-005**: The README MUST include guidance on which eval judges are most useful for measuring skill quality improvement.
- **FR-006**: The walkthrough MUST show a before/after comparison of eval scores to illustrate measurable improvement.
- **FR-007**: The documentation MUST NOT introduce any new code, skills, or eval configuration files to the cc-skill plugin.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user with both plugins installed can follow the documented workflow end-to-end without consulting external documentation.
- **SC-002**: The walkthrough example covers all 6 steps with representative output at each step.
- **SC-003**: The judges guidance section recommends at least 3 specific judge categories relevant to skill quality evaluation.
- **SC-004**: The new README section follows the existing README's heading hierarchy and tone, and does not duplicate content already present.

## Assumptions

- Both the cc-skill plugin and agent-eval-harness plugin are installed and functional in the user's Claude Code environment.
- The user has at least one SKILL.md file they want to evaluate and improve.
- The walkthrough uses a real, publicly available SKILL.md as its example (selected during implementation).
- Representative output in the walkthrough is simplified for readability rather than showing raw tool output verbatim.
- The agent-eval-harness commands (`/eval-analyze`, `/eval-dataset`, `/eval-run`) work as documented in that project's own README.
