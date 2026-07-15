# Research: Three-Layer Skill Linting

## R1: Three-Layer Linting Model Source

**Decision**: Adopt Bilgin Ibryam's three-layer model (deterministic, best-practice, substance) from "5 Software Disciplines That Keep AI Skills From Rotting" (July 2026).

**Rationale**: The model maps directly to different cost/value tradeoffs: Layer 1 is fast and binary (can run on every save), Layer 2 is the existing checker's core (LLM-evaluated patterns), Layer 3 is expensive and optional (deep qualitative review). This layering lets users choose their analysis depth.

**Alternatives considered**:
- Single-pass expansion (add all checks to existing flow): rejected because it conflates cheap structural checks with expensive substance review, forcing users to pay for everything on every run.
- Two-tier model (patterns + principles): rejected because it misses the deterministic layer entirely and doesn't capture the substance review depth.

## R2: New Patterns from 9 Principles

**Decision**: Add 3 genuinely new patterns (Process over Prose, Anticipate the Excuse, Stay in Scope) and treat the remaining 6 principles as enrichments to existing patterns.

**Rationale**: Gap analysis from brainstorm #02 showed that 6 of the 9 principles already map to existing patterns. Only P3, P5, and P7 represent checks not covered by the current 14 patterns. Adding them as patterns 15-17 keeps the numbering clean and avoids redundancy.

**Alternatives considered**:
- Add all 9 as separate patterns (total 23): rejected because 6 overlap with existing patterns, creating redundant checks.
- Add 3 as principles in a separate section: rejected because maintaining two evaluation vocabularies (patterns vs. principles) adds complexity without benefit.

## R3: Platform Character Limits

**Decision**: Check description field against 1024 characters (Agent Skills spec) and description + when_to_use combined against 1536 characters (Claude Code).

**Rationale**: These are the current published limits. Agent Skills spec enforces 1024 on the description field. Claude Code uses description + when_to_use for routing, with a combined budget of ~1536 characters.

**Alternatives considered**:
- Only check Agent Skills limit: rejected because many skills target Claude Code, which has different constraints.
- Hard-code a single limit: rejected because the two platforms have genuinely different constraints.

## R4: Token Estimation Heuristic

**Decision**: Use word count * 1.3 as the token estimation heuristic for the 5000-token body threshold.

**Rationale**: Average English text tokenizes to roughly 1.3 tokens per word across common tokenizers (cl100k_base, o200k_base). This is accurate enough for threshold comparison (we need "roughly 5000 tokens" not "exactly 5000 tokens"). No external tokenizer dependency needed.

**Alternatives considered**:
- Character count / 4: less accurate for mixed content (code blocks inflate character count).
- Precise tokenizer (tiktoken): would require external tooling; the checker runs as LLM-interpreted Markdown with no script execution.

## R5: Known Frontmatter Fields

**Decision**: Validate against the field set: `name`, `description`, `argument-hint`, `user-invocable`, `disable-model-invocation`, `allowed-tools`.

**Rationale**: These are the documented fields in the Claude Code skill system and Agent Skills spec. Unknown fields suggest the author may have typos or is using unsupported features.

**Alternatives considered**:
- No field validation: rejected because typos in field names (e.g., `arguement-hint`) silently fail and are hard to debug.
- Strict rejection of unknown fields: rejected because new fields may be added to the platform; a warning is more appropriate than a hard failure.

## R6: Layer 3 Substance Review Structure

**Decision**: Layer 3 produces a narrative with labeled subsections (Purpose Sensibility, Harmful Output Risk, Example Realism, Workflow Completeness) and an Overall Verdict line with pass/concern/fail rating.

**Rationale**: A structured verdict gives authors clear categories to address while the narrative format allows nuanced assessment that a table cannot capture. The four questions come from the brainstorm's senior-engineer framing.

**Alternatives considered**:
- Free-form narrative only: rejected because it's harder for authors to extract actionable items.
- Table format: rejected because qualitative assessment loses nuance when compressed into table cells.
