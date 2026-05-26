# Research: Measure-Enhance-Measure Workflow Documentation

## R1: Agent-Eval-Harness Command Interface

**Decision**: Reference the harness commands by their slash-command names (`/eval-analyze`, `/eval-dataset`, `/eval-run`) since users interact via Claude Code skills, not CLI scripts.

**Rationale**: The harness is a Claude Code plugin. Users invoke skills, not Python modules. Using slash-command names matches what they'll type.

**Alternatives considered**: Referencing Python scripts directly (rejected: implementation detail), referencing the harness API (rejected: no public API, skill invocation is the interface).

## R2: Walkthrough Example Skill

**Decision**: Use a hypothetical simplified skill as the walkthrough example. Describe a minimal "code-review" skill with 3-4 patterns present and several absent, making it a good candidate for enhancement.

**Rationale**: A hypothetical skill lets us control which patterns are present/absent and show clear improvement. Using a real external skill would couple our docs to another project's evolution and require permission considerations.

**Alternatives considered**: Using one of cc-skill's own skills (rejected: circular, and the spec explicitly excludes self-evaluation), using a public skill from superpowers plugin (rejected: external dependency that may change).

## R3: Judge Categories for Skill Quality

**Decision**: Recommend three judge categories aligned with the eval-harness judge types.

**Rationale**: The harness supports inline checks (Python snippets returning bool), LLM judges (prompt-based scoring), and pairwise judges (comparing two runs). Each maps naturally to a different aspect of skill quality.

**Research findings**:
- **Inline checks** work well for structural verification: does the skill output contain expected sections, did it produce the right file artifacts, is the pattern count correct?
- **LLM judges** work well for qualitative assessment: is the output actionable, does it preserve the original skill's intent, is the guidance clear?
- **Pairwise judges** work well for measuring improvement: compare baseline run artifacts against enhanced run artifacts to score which is better.

**Alternatives considered**: Recommending specific judge implementations with code (rejected: FR-007 prohibits shipping eval configs), recommending only LLM judges (rejected: misses the structural verification that inline checks handle better).

## R4: Sample Output Fidelity

**Decision**: Show simplified, representative output at each step rather than full verbatim output.

**Rationale**: Full eval-harness output includes JSON metadata, token counts, timing information, and other details that would overwhelm the README. Simplified output focuses on the key information: what was analyzed, what scores were produced, what changed.

**Alternatives considered**: Full verbatim output (rejected: too long, breaks reading flow), no output at all (rejected: users need to know what to expect).
