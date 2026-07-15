# Data Model: Three-Layer Skill Linting

## Entities

### Pattern

A skill-authoring best practice evaluated by the checker and applied by the enhancer.

| Attribute | Description |
|-----------|-------------|
| Number | Sequential identifier (1-17) |
| Name | Human-readable name (e.g., "Activation Metadata") |
| Category | Grouping: Discovery, Context Economy, Instruction Calibration, Workflow Control, Executable Code, Meta, Workflow Quality |
| Applicability | Universal, Conditional (with condition description), or N/A |
| Detection Signals | List of observable indicators in the skill text |
| Quality Criteria | Two tiers: Strong (excellent implementation) and Present (exists but could improve) |
| Improvement Guidance | Actionable instructions for reaching "present" or "strong" |

**Relationships**: Patterns belong to exactly one Category. Patterns 1-14 are existing; 15-17 are new.

### Deterministic Check

A structural validation in Layer 1 with tri-state outcomes. The checks are performed by the LLM reading the skill content (not external tooling), but have deterministic criteria: a given input always produces the same result.

| Attribute | Description |
|-----------|-------------|
| Name | Check identifier (e.g., "frontmatter-presence") |
| Result | PASS (meets requirement), WARN (exceeds advisory threshold), or FAIL (missing required element) |
| Threshold | Numeric limit or structural requirement |
| Remediation Hint | Brief instruction for fixing a failure or addressing a warning |

**Checks defined**:
1. Frontmatter presence (FAIL if missing)
2. Required fields: name, description (FAIL if missing)
3. Description character count vs. 1024/1536 limits (WARN if exceeded)
4. Known frontmatter fields validation (WARN on unknown)
5. Body line count vs. 500-line threshold (WARN if exceeded)
6. Token budget estimate vs. 5000-token threshold (WARN if exceeded)

### Principle Enrichment

Additional detection signal added to an existing pattern based on the 9 design principles.

Of the 9 principles, 3 became new patterns (P3, P5, P7), 5 became enrichments to existing patterns, and 1 (P2: "Name Things Like a User") is already covered by Pattern 1 (Activation Metadata) without needing additional signals.

| Attribute | Description |
|-----------|-------------|
| Target Pattern | Pattern number being enriched (1, 3, 5, 6, or 13) |
| Source Principle | Principle reference (P1, P4, P6, P8/P9, or agentskills.io) |
| Signal | Detection signal text to add |
| Impact on Quality | How this affects strong/present threshold |

**Enrichments defined**:
1. Pattern 1 + P1: Character budget check (1024/1536), routing rule vs. summary distinction
2. Pattern 3 + agentskills.io: "Omit what the model knows"
3. Pattern 5 + agentskills.io: "Defaults not menus", "match specificity to fragility"
4. Pattern 6 + P4: "Narrow imperative for fragile steps" (when NOT to explain)
5. Pattern 13 + P6: "Detect deterministic steps written as LLM prose"

### Substance Review (Layer 3)

Qualitative assessment produced when `--deep` is used.

| Attribute | Description |
|-----------|-------------|
| Purpose Sensibility | Does the skill do something sensible for its stated purpose? |
| Harmful Output Risk | Could instructions produce harmful output if followed literally? |
| Example Realism | Are the examples realistic or contrived? |
| Workflow Completeness | Does the workflow have dead ends or unreachable branches? |
| Overall Verdict | pass, concern, or fail with rationale |
