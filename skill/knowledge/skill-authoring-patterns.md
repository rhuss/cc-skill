# Skill-Authoring Patterns

14 patterns for writing effective Claude Code SKILL.md files. Organized by category with detection signals, quality criteria, and improvement guidance for each.

## Discovery

### 1. Activation Metadata

**Applicability**: Universal

**What it is**: YAML frontmatter with `name`, `description`, and optional fields (`argument-hint`, `user-invocable`, `disable-model-invocation`) that controls when Claude selects this skill.

**Detection signals**:
- YAML frontmatter block exists (`---` delimiters)
- `name` field present with namespaced format (`plugin:skill`)
- `description` field present with action-oriented text
- Description includes trigger phrases matching intended use cases

**Quality criteria**:
- **Strong**: Description names specific trigger verbs and exclusion phrases. A reader can predict which requests activate it without reading the body. `argument-hint` present if the skill accepts input.
- **Present**: Frontmatter exists but description is vague or generic ("Helps with X").

**Improvement guidance**: Rewrite the description so it reads like a routing rule. List the 3-5 most common user phrasings that should trigger this skill. Add `argument-hint` if the skill takes input.

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

**Quality criteria**:
- **Strong**: Every read or load is conditional or scoped. Knowledge files are loaded only when the skill's logic requires them. No "load all files in directory" patterns.
- **Present**: Some files are loaded conditionally, but others are loaded unconditionally regardless of need.

**Improvement guidance**: Audit every Read/Glob/Grep instruction. Make large loads conditional on whether the skill's current path needs them. Prefer targeted reads (specific sections, line ranges) over full-file reads for large files.

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

**Quality criteria**:
- **Strong**: A reader can tell which parts are "follow exactly" vs. "use your judgment." Output formats are specified precisely. Analysis and reasoning steps allow adaptation. Workflow steps that have their own branching logic (e.g., "if available, do X; if not, skip") are not additionally labeled "Optional" in headings or introductory text, because the branch already encodes the skip condition. No step uses soft language ("may", "consider", "optionally") on actions that must happen when their condition is met.
- **Present**: Instructions exist but everything is the same level of specificity (either all rigid or all vague). Or: steps have correct branching logic but headings or framing undermine it with soft labels that invite skipping the branch check entirely.

**Improvement guidance**: Mark output-format sections as rigid (exact templates, required fields). Mark analysis and decision sections as flexible (criteria to consider, not exact steps to follow). Use imperative verbs for rigid steps, descriptive language for flexible ones. Audit step headings and introductory sentences for weak control-flow declarations: if a step says "(Optional)" but contains "if X, do Y; if not, skip," remove the "Optional" label. The branching logic is the control flow; the label undermines it by giving the LLM permission to skip the branch check itself.

---

### 6. Explain-the-Why

**Applicability**: Universal

**What it is**: Reasoning behind non-obvious instructions so Claude can make good judgment calls in edge cases.

**Detection signals**:
- "Because", "so that", "this ensures", "the reason" phrases near instructions
- Context for constraints ("500 lines because context budget")
- Rationale for ordering choices, format decisions, or workflow steps

**Quality criteria**:
- **Strong**: Every non-obvious constraint includes its reason. A reader could infer the right action in an unlisted edge case by understanding the intent.
- **Present**: Some reasons given, but many instructions are bare imperatives without context.

**Improvement guidance**: For each instruction, ask "would Claude know why if this failed?" If not, add a brief reason. Focus on constraints, ordering requirements, and format choices. One sentence is enough.

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

**Quality criteria**:
- **Strong**: Scripts handle the deterministic work (parsing, validation, data transformation). LLM handles the judgment work (analysis, recommendations, writing). Scripts are referenced by path and called with clear arguments. Error handling covers missing scripts.
- **Present**: Some code exists but it's inline in the SKILL.md rather than in scripts, or scripts exist but error handling is missing.

**Improvement guidance**: Move deterministic logic (parsing, validation, formatting) into scripts in a `scripts/` directory. Keep judgment and analysis in the SKILL.md instructions. Reference scripts using `${CLAUDE_PLUGIN_ROOT}/scripts/` paths. Add error handling for missing or failing scripts.

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
