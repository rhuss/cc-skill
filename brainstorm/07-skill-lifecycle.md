# Brainstorm: Skill Lifecycle Expansion

**Date:** 2026-07-14
**Status:** active

## Problem Framing

The cc-skill plugin currently covers two of Bilgin's five software disciplines for skills: linting (`skill:check`) and evals (`skill:measure`). Three disciplines remain unaddressed: scanning (security), dependencies (package management), and observability (production monitoring).

Not all five disciplines belong in a single plugin. Dependencies are better served by dedicated package managers like Microsoft's apm. Observability requires runtime instrumentation that a static-analysis tool cannot provide. But two capabilities fit naturally:

1. **Security scanning** complements linting. A skill can pass all 17 pattern checks and still contain unsafe instructions. Scanning addresses a fundamentally different risk surface.
2. **Description optimization** sits between linting and evals. The current checker evaluates whether activation metadata is present and well-structured, but doesn't test whether it actually triggers correctly against realistic prompts.

These are the two most valuable lifecycle additions for a plugin focused on skill quality.

## Source Material

- Bilgin Ibryam, "5 Software Disciplines That Keep AI Skills From Rotting" (sections on Skill Scanning, Skill Dependencies, Skill Observability)
- NVIDIA SkillSpector, Cisco Skill Scanner, SkillWard (Fangcun-AI), Snyk Agent Scan (referenced scanning tools)
- agentskills.io "Optimizing skill descriptions" (referenced but not yet published)
- OpenAI Codex eval pattern (prompt dataset with negative controls informs description testing)
- Guy Podjarny, "Skills Are the New Code" talk (framing skills as supply-chain artifacts)

## Approaches Considered

### A: Scan Only

Add `skill:scan` for security/safety analysis of skills before trusting them.

- Pros: Addresses the most critical lifecycle gap (security), clear use case
- Cons: Doesn't address the description optimization gap

### B: Scan + Description Optimizer (Chosen)

Add two new commands:

**`skill:scan`** for security/safety analysis
**`skill:describe`** for testing and optimizing activation metadata

- Pros: Covers the two lifecycle gaps most suited to static analysis, complements existing linting and eval capabilities
- Cons: Two new skills to maintain

### C: Full Lifecycle Toolkit

All of B plus lifecycle metadata checks (staleness detection, owner field, last-tested date) and observability hooks.

- Pros: Most comprehensive coverage
- Cons: Observability is a runtime concern that doesn't fit a static-analysis plugin. Lifecycle metadata checks can be folded into `skill:check` (see brainstorm #05, Layer 2 enrichments for P8/P9) rather than needing a separate tool. Over-scoping the plugin.

## Decision

**Chosen approach: B (Scan + Description Optimizer)**

Dependencies and observability are explicitly out of scope. Dependencies need package management infrastructure (manifests, lockfiles, registries) that doesn't belong in a quality-focused plugin. Observability needs runtime instrumentation. Both are better served by dedicated tools.

Lifecycle metadata (P8 staleness, P9 run evidence) is in scope but belongs in the expanded `skill:check` (brainstorm #05), not in separate commands.

## Key Requirements

### New command: `skill:scan`

**Purpose:** Analyze a SKILL.md for security risks, unsafe instructions, and safety gaps before trusting it, especially for third-party skills.

**Three risk categories** (from Bilgin's framework):

1. **Malicious skills**: Instructions designed to cause harm
   - Data exfiltration patterns (sending file contents to external URLs)
   - Credential harvesting (reading .env, .ssh, credentials files, auth tokens)
   - Destructive operations disguised as helpful steps (rm -rf, git push --force, DROP TABLE)
   - Hidden instructions in HTML comments or obscured text
   - Prompt injection attempts (instructions that override system prompts or other skills)
   - Social engineering patterns (instructions that manipulate user trust to approve dangerous actions)

2. **Negligent skills**: Missing safety boundaries
   - Destructive file operations without confirmation gates
   - External API calls without error handling or rate limiting
   - Shell command execution without input sanitization
   - Missing rollback or undo mechanisms for irreversible operations
   - Overly broad tool permissions (no `allowed-tools` restrictions on high-risk skills)
   - Missing `user-invocable: true` on skills that should require explicit invocation

3. **Vulnerable skills**: Exposure of secrets or unsafe flows
   - Instructions that read or log sensitive files (.env, credentials, API keys)
   - Output patterns that could leak secrets (printing env vars, logging auth headers)
   - Unvalidated external input passed to shell commands (injection vectors)
   - Skills that download and execute remote code
   - Hardcoded URLs, tokens, or credentials in the skill body

**Analysis approach** (combining techniques from referenced tools):

- Static pattern matching: Regex-based detection of known-dangerous patterns (fastest, most false positives)
- Data-flow analysis: Track how user input flows through instructions to tool invocations
- Dependency check: Verify referenced scripts, files, and external resources exist and are safe
- Model-assisted review: For ambiguous cases, ask the model "could this instruction be used to harm the user's system?"

**Output format:**

```
## Skill Security Scan

**File**: `<path>`
**Risk Level**: low | medium | high | critical

### Findings

| # | Category | Severity | Finding | Location |
|---|----------|----------|---------|----------|
| 1 | malicious | critical | Sends file contents to external URL | Line 42 |
| 2 | negligent | medium | rm -rf without confirmation gate | Line 87 |
| 3 | vulnerable | low | Reads .env file contents | Line 23 |

### Recommendations
- [specific remediation for each finding]
```

**Design principles:**
- Conservative by default: flag potential issues, don't silently pass
- Low false-positive rate for "critical" findings (high confidence required)
- Allow "medium" and "low" to have some false positives (user reviews)
- Always explain WHY something is flagged (not just WHAT)

### New command: `skill:describe`

**Purpose:** Test how well a skill's activation metadata (description, name, when_to_use) performs as a routing signal, and suggest improvements.

**Approach** (informed by Codex eval pattern's typed prompt datasets):

1. **Generate test prompts** across four categories:
   - Explicit: Direct invocations naming the skill ("use skill X to do Y")
   - Implicit: Natural language that should trigger the skill based on its description
   - Contextual: Skill-relevant requests embedded in broader context
   - Negative: Requests that sound related but should NOT trigger the skill

2. **Evaluate routing accuracy**: For each test prompt, predict whether Claude would select this skill based on the description alone (no body loaded). Score:
   - True positive: skill should fire, description supports it
   - False negative: skill should fire, description doesn't support it (missed trigger)
   - True negative: skill shouldn't fire, description correctly excludes it
   - False positive: skill shouldn't fire, description incorrectly attracts it (over-triggering)

3. **Produce optimization suggestions**:
   - Missing trigger phrases (from false negatives)
   - Missing exclusion clauses (from false positives)
   - Character budget analysis (description length vs. 1024/1536 limits)
   - Comparison with adjacent skills' descriptions (collision detection)

4. **Generate improved description**: Propose a rewritten description that addresses the gaps found. Let the user apply or skip.

**Output format:**

```
## Description Optimization

**File**: `<path>`
**Current description**: "<first 100 chars>..."
**Description length**: N chars (limit: 1024/1536)

### Routing Test Results

| # | Type | Prompt | Expected | Predicted | Result |
|---|------|--------|----------|-----------|--------|
| 1 | explicit | "Check this skill" | trigger | trigger | TP |
| 2 | implicit | "Is my skill good?" | trigger | no-trigger | FN |
| 3 | negative | "Write a new skill" | no-trigger | no-trigger | TN |

**Accuracy**: X/Y correct (Z%)
**False negatives**: N (missed triggers)
**False positives**: N (over-triggers)

### Suggested Description

[improved description text]

### Changes Made
- Added trigger phrase "..." to catch implicit invocations
- Added exclusion "Do NOT use for ..." to prevent false positives
- Reduced from N to M chars to stay within budget
```

**Interaction with skill:check**: The current Activation Metadata pattern (pattern 1) evaluates description quality structurally. `skill:describe` tests it behaviorally. They complement each other: check tells you if the description is well-formed, describe tells you if it actually works.

### What's explicitly out of scope

- **Skill dependencies / package management**: Better served by Microsoft's apm or similar. This plugin doesn't manage installations, manifests, or lockfiles.
- **Skill observability / production monitoring**: Requires runtime instrumentation. This plugin does static analysis. Observability signals (which skills fire, which fail, which are unused) belong in agent governance or tracing tools.
- **Skill registries / marketplaces**: Discovery and distribution infrastructure, not quality analysis.
- **Sandbox execution**: Running skills in isolation to observe behavior (SkillWard's approach) is an eval concern, not a static-analysis concern. The eval framework (brainstorm #06) is the right place for behavioral testing.

## Open Questions

- Should `skill:scan` be integrated into `skill:check` as an optional layer, or kept as a completely separate command? Argument for separate: different mental model (quality vs. security). Argument for integrated: one command to rule them all.
- How to handle false positives in scanning? A skill that legitimately needs to read `.env` (e.g., a deployment skill) would trigger a "vulnerable" finding. Should there be a way to mark findings as accepted/suppressed?
- For `skill:describe`, how many test prompts should be generated per category? The Codex pattern suggests 10-20 total. For description testing, 3-5 per category (12-20 total) seems right.
- Should `skill:describe` test against multiple models? A description that triggers correctly on Opus might fail on Haiku. Bilgin notes this model-sensitivity explicitly.
