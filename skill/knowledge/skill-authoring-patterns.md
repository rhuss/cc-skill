# Skill-Authoring Patterns

17 patterns for writing effective Claude Code SKILL.md files. Organized by category with detection signals, quality criteria, and improvement guidance for each.

## Discovery

### 1. Activation Metadata

**Applicability**: Universal

**What it is**: YAML frontmatter with `name`, `description`, and optional fields (`argument-hint`, `user-invocable`, `disable-model-invocation`) that controls when Claude selects this skill.

**Detection signals**:
- YAML frontmatter block exists (`---` delimiters)
- `name` field present with namespaced format (`plugin:skill`)
- `description` field present with action-oriented text
- Description includes trigger phrases matching intended use cases
- Description character count within platform limits (1024 for Agent Skills spec, 1536 for Claude Code description + when_to_use combined)
- Description reads as a routing rule (directs activation), not a summary of what the skill does

**Quality criteria**:
- **Strong**: Description names specific trigger verbs and exclusion phrases. A reader can predict which requests activate it without reading the body. `argument-hint` present if the skill accepts input. Description stays within platform character limits (1024/1536).
- **Present**: Frontmatter exists but description is vague or generic ("Helps with X"), or description exceeds platform character limits.

**Improvement guidance**: Rewrite the description so it reads like a routing rule, not a summary. A routing rule directs activation ("Use when X, Y, Z"); a summary describes the skill ("This skill does X"). List the 3-5 most common user phrasings that should trigger this skill. Add `argument-hint` if the skill takes input. Check character count against platform limits: 1024 for Agent Skills spec, 1536 for Claude Code description + when_to_use combined.

---

### 2. Exclusion Clause

**Applicability**: Universal

**What it is**: A "Do NOT use for" or "Skip when" statement in the description or body that prevents false activation.

**Detection signals**:
- Explicit negation phrases in description or early body ("Do NOT use", "Skip when", "Not for")
- Anti-patterns or non-trigger scenarios listed
- Clear boundary between this skill and adjacent ones

**Quality criteria**:
- **Strong**: Names specific adjacent skills or scenarios that are commonly confused with this one. Exclusions are actionable (Claude can route away based on them).
- **Present**: Generic exclusion exists ("not for general use") without naming what to use instead.

**Improvement guidance**: Identify the 2-3 most likely misroutes. Name the adjacent skill or behavior Claude should choose instead. Place exclusions in the description (not buried in the body) so routing checks see them.

---

## Context Economy

### 3. Context Budget

**Applicability**: Universal

**What it is**: Awareness of token cost. The skill loads only what it needs and avoids pulling in large reference material unconditionally.

**Detection signals**:
- Conditional loading ("if X exists, read it")
- Scoped reads (specific files, line ranges, sections) rather than "read everything"
- No unconditional loading of large knowledge files or entire directories
- File size awareness (line limits, pagination)
- Omits information the model already knows (general programming knowledge, language syntax, well-known API conventions) rather than restating it
- Focuses token budget on project-specific context the model cannot infer

**Quality criteria**:
- **Strong**: Every read or load is conditional or scoped. Knowledge files are loaded only when the skill's logic requires them. No "load all files in directory" patterns. Instructions do not restate knowledge the model already has; they focus on project-specific details, conventions, and constraints.
- **Present**: Some files are loaded conditionally, but others are loaded unconditionally regardless of need. Or the skill includes general knowledge the model already possesses, wasting context budget.

**Improvement guidance**: Audit every Read/Glob/Grep instruction. Make large loads conditional on whether the skill's current path needs them. Prefer targeted reads (specific sections, line ranges) over full-file reads for large files. Remove instructions that restate what the model already knows (standard library behavior, common patterns, language syntax). Replace with project-specific context the model cannot infer.

---

### 4. Progressive Disclosure

**Applicability**: Conditional (skills longer than ~200 lines or with distinct reference material)

**Condition**: The skill has enough content that splitting into a main SKILL.md plus reference files improves readability and reduces token cost.

**Detection signals**:
- SKILL.md stays under 500 lines
- Reference material split into separate files in the same directory
- SKILL.md references companion files with conditional loading
- Clear separation between core instructions and supplementary material

**Quality criteria**:
- **Strong**: Core workflow fits in SKILL.md. Reference data, examples, and edge cases live in companion files loaded only when needed. Companion files have descriptive names.
- **Present**: SKILL.md is long but has some structure, or references exist but are loaded unconditionally.

**Improvement guidance**: Move reference tables, example libraries, and edge-case catalogs into companion files. Keep the main SKILL.md focused on the decision-making workflow. Name companion files descriptively (e.g., `examples.md`, `reference.md`, `gotchas.md`).

---

## Instruction Calibration

### 5. Control Tuning

**Applicability**: Universal

**What it is**: The right level of specificity in instructions. Rigid steps where precision matters, flexible guidance where judgment matters.

**Detection signals**:
- Mix of exact commands/formats (rigid) and open-ended guidance (flexible)
- Rigid sections for output formats, validation steps, error handling
- Flexible sections for analysis, creative decisions, user interaction
- No over-specification of judgment calls or under-specification of exact outputs
- No weak control-flow declarations: steps or headings labeled "Optional", "if desired", "consider", or "you may" when the step contains conditional logic that already handles the skip case (making the "Optional" label redundant and permission-granting)
- Sensible defaults enforced instead of "menu-style" options that offer the LLM choices (e.g., "choose format A, B, or C" when format A is almost always correct)
- Specificity of instructions matches fragility of the step: fragile steps (where small deviations cause failures) get exact commands; resilient steps (where multiple approaches work) get flexible guidance

**Quality criteria**:
- **Strong**: A reader can tell which parts are "follow exactly" vs. "use your judgment." Output formats are specified precisely. Analysis and reasoning steps allow adaptation. Workflow steps that have their own branching logic (e.g., "if available, do X; if not, skip") are not additionally labeled "Optional" in headings or introductory text, because the branch already encodes the skip condition. No step uses soft language ("may", "consider", "optionally") on actions that must happen when their condition is met. Decisions with a clear best default enforce that default rather than presenting a menu of options. Fragile steps use narrow, exact instructions; resilient steps allow flexibility.
- **Present**: Instructions exist but everything is the same level of specificity (either all rigid or all vague). Or: steps have correct branching logic but headings or framing undermine it with soft labels that invite skipping the branch check entirely. Or: the skill presents menus of choices where a sensible default should be enforced, or applies uniform specificity regardless of step fragility.

**Improvement guidance**: Mark output-format sections as rigid (exact templates, required fields). Mark analysis and decision sections as flexible (criteria to consider, not exact steps to follow). Use imperative verbs for rigid steps, descriptive language for flexible ones. Audit step headings and introductory sentences for weak control-flow declarations: if a step says "(Optional)" but contains "if X, do Y; if not, skip," remove the "Optional" label. The branching logic is the control flow; the label undermines it by giving the LLM permission to skip the branch check itself. Replace menu-style option lists with enforced defaults where one choice is clearly superior. Match instruction specificity to step fragility: exact commands for steps where deviation causes failures, flexible guidance for steps where multiple approaches work equally well.

---

### 6. Explain-the-Why

**Applicability**: Universal

**What it is**: Reasoning behind non-obvious instructions so Claude can make good judgment calls in edge cases.

**Detection signals**:
- "Because", "so that", "this ensures", "the reason" phrases near instructions
- Context for constraints ("500 lines because context budget")
- Rationale for ordering choices, format decisions, or workflow steps
- Fragile steps use narrow, specific imperatives with rationale rather than broad imperatives like "handle errors appropriately" or "format output correctly"

**Quality criteria**:
- **Strong**: Every non-obvious constraint includes its reason. A reader could infer the right action in an unlisted edge case by understanding the intent. Fragile steps (where deviation causes failures) pair specific instructions with a reason rather than using broad imperatives that invite interpretation.
- **Present**: Some reasons given, but many instructions are bare imperatives without context. Or fragile steps rely on broad imperatives ("handle errors appropriately") instead of naming the specific error and its required response.

**Improvement guidance**: For each instruction, ask "would Claude know why if this failed?" If not, add a brief reason. Focus on constraints, ordering requirements, and format choices. One sentence is enough. For fragile steps, replace broad imperatives with narrow ones: instead of "handle errors appropriately," write "if the file is missing, return error X and stop, because continuing without the file produces silent corruption."

---

### 7. Template Scaffold

**Applicability**: Conditional (skills that produce structured output)

**Condition**: The skill generates output with a consistent structure (reports, checklists, code, formatted responses).

**Detection signals**:
- Output templates with placeholders
- Markdown/code blocks showing expected output structure
- Field descriptions for template variables
- Example outputs matching the template

**Quality criteria**:
- **Strong**: Complete output template with all fields defined. Placeholders use descriptive names. At least one filled example demonstrates the template in use.
- **Present**: Partial template or output described in prose without a concrete example.

**Improvement guidance**: Write the full output template with placeholder names that describe expected content. Add one filled example. If the output varies by scenario, show the most common variant as the template and describe variations separately.

---

### 8. In-Skill Examples

**Applicability**: Conditional (skills with non-obvious input/output mapping)

**Condition**: The relationship between input and expected output is not immediately obvious from the instructions alone.

**Detection signals**:
- Input/output pairs showing expected behavior
- "Example:" or "For instance:" blocks with concrete scenarios
- Before/after comparisons
- Sample invocations with expected results

**Quality criteria**:
- **Strong**: Examples cover the common case and at least one edge case. Each example shows both input and expected output. Examples are realistic, not contrived.
- **Present**: Examples exist but only cover the happy path, or show input without expected output.

**Improvement guidance**: Add 2-3 examples covering: the most common use case, an edge case, and (if applicable) a case where the skill should decline or redirect. Show full input/output pairs.

---

### 9. Known Gotchas

**Applicability**: Conditional (skills operating in domains with common pitfalls)

**Condition**: The skill works in an area where practitioners commonly make mistakes or where counterintuitive behavior exists.

**Detection signals**:
- "Warning:", "Note:", "Common mistake:" sections
- Explicit pitfall descriptions with mitigations
- "Do not confuse X with Y" statements
- Edge cases called out with handling instructions

**Quality criteria**:
- **Strong**: Gotchas are specific to this skill's domain, not generic advice. Each gotcha includes what goes wrong and how to avoid it. Gotchas are placed near the relevant instruction.
- **Present**: Generic warnings exist but lack specificity, or gotchas are collected at the end rather than inline.

**Improvement guidance**: Interview the domain for its top 3 mistakes. Write each as: "When X happens, you might think Y, but Z." Place each gotcha near the instruction where it matters, not in a separate section.

---

## Workflow Control

### 10. Execution Checklist

**Applicability**: Conditional (skills with multi-step procedures)

**Condition**: The skill has a procedure with 3+ steps that must execute in a specific order.

**Detection signals**:
- Numbered step sequences
- Checkpoint markers between phases
- "Before proceeding, verify..." statements
- Clear phase/step identification

**Quality criteria**:
- **Strong**: Steps are numbered and ordered. Each step has a clear completion criterion. Dependencies between steps are explicit. The skill can recover or halt gracefully at any checkpoint.
- **Present**: Steps exist but ordering is implicit, or completion criteria are missing.

**Improvement guidance**: Number every step. Add a completion check after each non-trivial step. Make dependencies explicit ("Step 3 requires output from Step 2"). Add halt conditions where failure should stop the workflow.

---

### 11. Self-Correcting Loop

**Applicability**: Conditional (skills that produce artifacts requiring validation)

**Condition**: The skill creates output (code, files, configurations) that can be validated programmatically.

**Detection signals**:
- "Run tests/checks after..." instructions
- Retry or fix loops ("if validation fails, adjust and retry")
- Validation commands with expected outcomes
- Maximum retry counts or bail-out conditions

**Quality criteria**:
- **Strong**: Validation step is mandatory (not optional). Fix loop has a maximum iteration count. Bail-out produces a clear error, not silent failure. Both success and failure paths are defined.
- **Present**: Validation mentioned but optional, or no retry limit defined.

**Improvement guidance**: Make validation mandatory after artifact creation. Define the validation command and expected outcome. Add a retry loop with a maximum count (typically 2-3). Define what happens when retries are exhausted.

---

### 12. Plan-Validate-Execute

**Applicability**: Conditional (skills that make changes to user files or external systems)

**Condition**: The skill modifies files, creates resources, or takes actions that are hard to reverse.

**Detection signals**:
- "First, propose..." or "Present plan for approval..." phases
- User confirmation gates before execution
- Dry-run or preview modes
- Separation between analysis/planning and execution

**Quality criteria**:
- **Strong**: Clear separation between planning and execution phases. User must explicitly approve before changes happen. Preview shows exactly what will change. Rollback or undo is addressed.
- **Present**: Some separation exists but user approval is implicit or skippable.

**Improvement guidance**: Split the workflow into: (1) analyze and propose changes, (2) present proposal with specifics, (3) wait for user approval, (4) execute. Never combine analysis and execution in a single step for destructive operations.

---

## Executable Code

### 13. Utility Bundle

**Applicability**: Conditional (skills that need helper scripts or programmatic logic)

**Condition**: The skill requires computation, file processing, or operations better handled by code than LLM reasoning.

**Detection signals**:
- `scripts/` directory with helper scripts
- Bash/Python code blocks with execution instructions
- `${CLAUDE_PLUGIN_ROOT}` references for script paths
- Tool integration (Bash, LSP, etc.) for programmatic operations
- No deterministic operations (parsing, counting, formatting, validation) written as LLM prose instructions when they could be delegated to scripts or tool calls

**Quality criteria**:
- **Strong**: Scripts handle the deterministic work (parsing, validation, data transformation). LLM handles the judgment work (analysis, recommendations, writing). Scripts are referenced by path and called with clear arguments. Error handling covers missing scripts. No deterministic steps are written as prose instructions for the LLM to interpret when a script or tool call would be more reliable.
- **Present**: Some code exists but it's inline in the SKILL.md rather than in scripts, or scripts exist but error handling is missing. Or deterministic operations (counting lines, parsing YAML, formatting output) are written as LLM prose instructions instead of being delegated to scripts.

**Improvement guidance**: Move deterministic logic (parsing, validation, formatting) into scripts in a `scripts/` directory. Keep judgment and analysis in the SKILL.md instructions. Reference scripts using `${CLAUDE_PLUGIN_ROOT}/scripts/` paths. Add error handling for missing or failing scripts. Audit instructions for deterministic steps written as LLM prose: if a step involves counting, parsing, formatting, or validating without judgment, consider delegating it to a script or tool call instead.

---

## Meta

### 14. Autonomy Calibration

**Applicability**: Universal

**What it is**: Frontmatter and body instructions that tune how much independence Claude has when running this skill.

**Detection signals**:
- `user-invocable` field in frontmatter
- `disable-model-invocation` field in frontmatter
- `allowed-tools` restrictions in frontmatter
- Explicit permission gates ("ask user before...", "do not proceed without approval")
- Tool restrictions or allowlists

**Quality criteria**:
- **Strong**: Autonomy level matches the skill's risk profile. Destructive skills require explicit approval. Read-only analysis skills allow autonomous execution. Tool restrictions are specific (not blanket allow/deny).
- **Present**: Some autonomy controls exist but don't match the risk profile (e.g., a read-only skill requires unnecessary approval, or a destructive skill lacks gates).

**Improvement guidance**: Assess the skill's risk: does it modify files, call external APIs, or take irreversible actions? High-risk skills need `user-invocable: true`, explicit approval gates, and possibly `allowed-tools` restrictions. Low-risk skills can allow model invocation and autonomous execution.

---

## Workflow Quality

### 15. Process over Prose

**Applicability**: Universal

**What it is**: Instructions written as actionable procedures (numbered steps, imperative verbs, decision points) rather than descriptive prose that explains concepts without directing action.

**Detection signals**:
- Numbered or ordered step sequences with imperative verbs ("Read the file", "Run the command", "Check the output")
- Decision points with explicit branches ("If X, do Y; otherwise, do Z")
- Entry conditions for each phase or section ("Before this step, you must have...")
- Exit conditions or completion criteria ("This step is done when...")
- Absence of long descriptive paragraphs that explain concepts without directing the next action

**Quality criteria**:
- **Strong**: Every section is actionable. A junior engineer reading the skill knows what to do next at every point. Steps use imperative verbs, include decision points with branches, and have clear entry/exit conditions. Descriptive context is brief and immediately followed by an action.
- **Present**: Some workflow steps exist but mixed with descriptive prose. The reader must infer what to do from explanatory text rather than following explicit instructions.

**Improvement guidance**: Restructure declarative text into numbered procedures with clear entry/exit conditions. Replace "The system handles errors by..." with "Step N: Handle errors. If X occurs, do Y." Every paragraph should end with or contain an action. If a section only describes and never directs, convert it to a step sequence or move it to a reference file.

---

### 16. Anticipate the Excuse

**Applicability**: Conditional (skills with non-negotiable rules or hard constraints)

**Condition**: The skill contains MUST, NEVER, or other non-negotiable rules where the LLM might rationalize an exception.

**Detection signals**:
- Rebuttal tables near mandatory rules listing likely rationalizations and why they are wrong
- "You might think... but" constructions that pre-answer objections
- Pre-answered objections placed adjacent to the rule they defend, not in a separate FAQ section
- MUST/NEVER rules paired with explicit counters to common workarounds

**Quality criteria**:
- **Strong**: Every MUST/NEVER rule has pre-written counters to 2+ likely rationalizations. Rebuttals are placed directly adjacent to the rule, not in a separate section. The counters name specific scenarios ("you might skip this because the file looks empty, but empty files still need the header for downstream tooling").
- **Present**: Some rebuttal content exists but does not cover all hard rules, or rebuttals are generic ("do not skip this step") without naming the specific rationalization being countered.

**Improvement guidance**: For each non-negotiable rule, list the 2-3 most likely agent rationalizations and provide explicit rebuttals. Place the rebuttals immediately after the rule, not in a separate FAQ. A rebuttal table works well: "You might think X because Y. Do not: Z." Name the specific scenario, not just "do not skip."

---

### 17. Stay in Scope

**Applicability**: Conditional (skills that modify files or system state)

**Condition**: The skill creates, modifies, or deletes files, or changes system state (environment variables, services, configurations).

**Detection signals**:
- Explicit positive scope constraints listing what files, directories, or resources the skill may touch
- Explicit negative scope constraints ("do NOT modify", "do NOT touch", "leave unchanged") listing what is off-limits
- File or directory path boundaries ("only modify files under src/", "never edit files outside the project root")
- Rationale for scope boundaries explaining why certain areas are protected

**Quality criteria**:
- **Strong**: Explicit positive constraints (what to touch) AND negative constraints (what not to touch) with rationale for each boundary. A reader can determine exactly which files or resources are in scope without inferring from context. Scope constraints are placed near the instructions they govern, not only in a preamble.
- **Present**: Some scope mention exists but boundaries are vague ("be careful about what you modify") or incomplete (only positive or only negative constraints, not both).

**Improvement guidance**: Add explicit scope constraints listing allowed and disallowed targets. Use both positive framing ("only modify files in X") and negative framing ("do NOT touch Y") because each catches cases the other misses. Include rationale for protected areas so the agent can make correct judgment calls at boundaries. Place scope constraints near the action instructions they govern, not only at the top of the skill.
